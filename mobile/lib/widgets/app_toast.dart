import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

void showAppToast(BuildContext context, String message,
    {bool error = false}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (_) => _ToastWidget(message: message, error: error),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 3), entry.remove);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool error;
  const _ToastWidget({required this.message, required this.error});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -2),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2, milliseconds: 600), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Positioned(
      top: mq.padding.top + 16,
      left: 0,
      right: 0,
      child: Material(
        type: MaterialType.transparency,
        child: SlideTransition(
          position: _slide,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              constraints: BoxConstraints(maxWidth: mq.size.width * 0.9),
              decoration: BoxDecoration(
                color: widget.error ? AppColors.error : AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 32,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: AppTheme.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
