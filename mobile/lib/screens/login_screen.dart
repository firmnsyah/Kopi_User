import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../state/session.dart' show AppSession;
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'overview_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxPinLength = 4;
  final _employeeCtrl = TextEditingController(text: '');
  String _pin = '';
  bool _loading = false;

  late final AnimationController _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
  late final Animation<double> _shake = Tween<double>(begin: 0, end: 1)
      .chain(CurveTween(curve: Curves.elasticIn))
      .animate(_shakeCtrl);

  @override
  void dispose() {
    _employeeCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _press(String n) {
    if (_pin.length >= _maxPinLength) return;
    setState(() => _pin += n);
  }

  void _del() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _clear() => setState(() => _pin = '');

  Future<void> _submit() async {
    final emp = _employeeCtrl.text.trim();
    if (emp.isEmpty) {
      _shakeCtrl.forward(from: 0);
      showAppToast(context, 'Masukkan Employee ID', error: true);
      return;
    }
    if (_pin.length < _maxPinLength) {
      _shakeCtrl.forward(from: 0);
      showAppToast(context, 'PIN harus 4 digit', error: true);
      return;
    }

    setState(() => _loading = true);
    final repo = context.read<Repository>();
    final res = await repo.clockIn(emp, _pin);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      await context
          .read<AppSession>()
          .signIn(res.employeeId!, role: res.role, token: res.token);
      if (!mounted) return;
      showAppToast(context, res.message);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => const OverviewScreen(),
      ));
    } else {
      _shakeCtrl.forward(from: 0);
      _clear();
      showAppToast(context, res.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/login_logo.png',
                          height: 100,
                        ),
                        const SizedBox(height: 48),
                        _employeeIdField(),
                        const SizedBox(height: 20),
                        _pinIndicator(),
                        const SizedBox(height: 20),
                        _keypad(),
                        const SizedBox(height: 16),
                        _clockInButton(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _employeeIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EMPLOYEE ID',
            style: AppTheme.label(size: 11, color: AppColors.secondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _employeeCtrl,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          style: AppTheme.body(size: 22, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'EMPLOYEE ID',
            hintStyle: AppTheme.body(
                size: 22,
                color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            filled: false,
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outlineVariant, width: 2),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outlineVariant, width: 2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _pinIndicator() {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) {
        final dx = _shake.value == 0 ? 0.0 : (_shake.value - 0.5) * 16;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SECURITY PIN',
              style: AppTheme.label(size: 11, color: AppColors.secondary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_maxPinLength, (i) {
                final filled = i < _pin.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: filled ? 18 : 14,
                    height: filled ? 18 : 14,
                    decoration: BoxDecoration(
                      color: filled
                          ? AppColors.tertiary
                          : AppColors.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypad() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 1; i <= 9; i++)
            _key(label: '$i', onTap: () => _press('$i')),
          _key(
            icon: Icons.backspace,
            onTap: _del,
            background: Colors.transparent,
            color: AppColors.secondaryFixedDim,
          ),
          _key(label: '0', onTap: () => _press('0')),
          _key(
            icon: Icons.close,
            onTap: _clear,
            background: Colors.transparent,
            color: AppColors.secondaryFixedDim,
          ),
        ],
      ),
    );
  }

  Widget _key({
    String? label,
    IconData? icon,
    required VoidCallback onTap,
    Color background = AppColors.surfaceContainerLow,
    Color color = AppColors.primary,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: label != null
              ? Text(label,
                  style: AppTheme.body(
                    size: 24,
                    weight: FontWeight.w700,
                    color: color,
                  ))
              : Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _clockInButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _loading ? null : _submit,
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Clock In',
                            style: AppTheme.headline(
                              size: 18,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            )),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward,
                            color: Colors.white, size: 24),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
