import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/employee.dart';
import '../utils/connectivity.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Employee>? _employees;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final online = await hasConnection();
    if (!mounted) return;
    if (!online) {
      setState(() => _loading = false);
      showAppToast(context, 'Tidak ada koneksi internet', error: true);
      return;
    }
    final list = await context.read<Repository>().getEmployees();
    if (!mounted) return;
    setState(() {
      _employees = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _employees == null || _employees!.isEmpty
                      ? Center(
                          child: Text('Belum ada karyawan.',
                              style: AppTheme.body(color: AppColors.secondary)),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: _employees!.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                _EmployeeCard(
                              employee: _employees![i],
                              onEdit: () => _showEditSheet(_employees![i]),
                              onToggle: () => _toggle(_employees![i]),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back,
                color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Manajemen Karyawan',
                style: AppTheme.headline(size: 16, color: AppColors.primary)),
          ),
          GestureDetector(
            onTap: _showAddSheet,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(Employee emp) async {
    final label = emp.active ? 'nonaktifkan' : 'aktifkan';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('${emp.active ? 'Nonaktifkan' : 'Aktifkan'} Karyawan?'),
        content: Text(
            'Yakin ingin $label akun ${emp.name} (${emp.employeeId})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              emp.active ? 'Nonaktifkan' : 'Aktifkan',
              style: TextStyle(
                  color: emp.active ? AppColors.error : AppColors.primary),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final online = await hasConnection();
    if (!mounted) return;
    if (!online) {
      showAppToast(context, 'Tidak ada koneksi internet', error: true);
      return;
    }

    try {
      final res = await context
          .read<Repository>()
          .toggleEmployeeActive(emp.employeeId);
      if (!mounted) return;
      showAppToast(context, res.message, error: !res.success);
      if (res.success) _load();
    } catch (_) {
      if (!mounted) return;
      showAppToast(context, 'Gagal mengubah status karyawan.', error: true);
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EmployeeForm(
        onSave: (id, name, role, pin) async {
          final res = await context.read<Repository>().createEmployee(
                employeeId: id,
                name: name,
                role: role,
                pin: pin,
              );
          if (!mounted) return;
          if (ctx.mounted) Navigator.pop(ctx);
          showAppToast(context, res.message, error: !res.success);
          if (res.success) _load();
        },
      ),
    );
  }

  void _showEditSheet(Employee emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EmployeeForm(
        existing: emp,
        onSave: (_, name, role, pin) async {
          final res = await context.read<Repository>().updateEmployee(
                employeeId: emp.employeeId,
                name: name,
                role: role,
                newPin: pin.isEmpty ? null : pin,
              );
          if (!mounted) return;
          if (ctx.mounted) Navigator.pop(ctx);
          showAppToast(context, res.message, error: !res.success);
          if (res.success) _load();
        },
      ),
    );
  }
}

// ── Kartu karyawan ────────────────────────────────────────────────────────────

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _EmployeeCard({
    required this.employee,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final e = employee;
    final initials = e.name.trim().isEmpty
        ? '?'
        : e.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: e.active
              ? AppColors.outlineVariant.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: e.active
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.outlineVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(initials,
                  style: AppTheme.headline(
                    size: 15,
                    weight: FontWeight.w800,
                    color: e.active ? AppColors.primary : AppColors.secondary,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name,
                    style: AppTheme.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: e.active ? AppColors.primary : AppColors.secondary,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(e.employeeId,
                        style:
                            AppTheme.label(size: 11, color: AppColors.secondary)),
                    const SizedBox(width: 8),
                    _RoleBadge(role: e.role),
                    if (!e.active) ...[
                      const SizedBox(width: 6),
                      _badge('Nonaktif', AppColors.error.withValues(alpha: 0.1),
                          AppColors.error),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              e.active ? Icons.person_off : Icons.how_to_reg,
              size: 20,
              color: e.active ? AppColors.error : AppColors.primary,
            ),
            tooltip: e.active ? 'Nonaktifkan' : 'Aktifkan',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: AppTheme.label(size: 9, color: fg)),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.outlineVariant.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Staff',
        style: AppTheme.label(
          size: 9,
          color: isAdmin ? AppColors.primary : AppColors.secondary,
        ),
      ),
    );
  }
}

// ── Form tambah / edit karyawan ───────────────────────────────────────────────

class _EmployeeForm extends StatefulWidget {
  final Employee? existing;
  final Future<void> Function(String id, String name, String role, String pin)
      onSave;

  const _EmployeeForm({this.existing, required this.onSave});

  @override
  State<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<_EmployeeForm> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String _role = 'staff';
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.existing!;
      _idCtrl.text = e.employeeId;
      _nameCtrl.text = e.name;
      _role = e.role;
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = _idCtrl.text.trim().toUpperCase();
    final name = _nameCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (!_isEdit && id.isEmpty) {
      _err('Employee ID tidak boleh kosong.');
      return;
    }
    if (name.isEmpty) {
      _err('Nama tidak boleh kosong.');
      return;
    }
    if (!_isEdit && pin.length != 4) {
      _err('PIN harus 4 digit.');
      return;
    }
    if (_isEdit && pin.isNotEmpty && pin.length != 4) {
      _err('PIN baru harus 4 digit.');
      return;
    }

    final online = await hasConnection();
    if (!mounted) return;
    if (!online) {
      _err('Tidak ada koneksi internet.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(id, name, _role, pin);
    } catch (_) {
      // repository errors are returned, not thrown — this is a safety net
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(_isEdit ? 'Edit Karyawan' : 'Tambah Karyawan',
              style: AppTheme.headline(size: 16)),
          const SizedBox(height: 20),
          // Employee ID (readonly when editing)
          _field(
            label: 'EMPLOYEE ID',
            controller: _idCtrl,
            hint: 'Contoh: KASIR-01',
            enabled: !_isEdit,
            caps: TextCapitalization.characters,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'NAMA',
            controller: _nameCtrl,
            hint: 'Nama lengkap',
            caps: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          // Role
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ROLE',
                  style: AppTheme.label(size: 11, color: AppColors.secondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _roleChip('staff', 'Staff'),
                  const SizedBox(width: 10),
                  _roleChip('admin', 'Admin'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _field(
            label: _isEdit ? 'PIN BARU (kosongkan jika tidak diubah)' : 'PIN (4 digit)',
            controller: _pinCtrl,
            hint: '••••',
            obscure: true,
            maxLength: 4,
            keyboard: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _saving ? null : _submit,
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text('SIMPAN',
                            style: AppTheme.label(
                                size: 13, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
    bool obscure = false,
    int? maxLength,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.label(size: 11, color: AppColors.secondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          maxLength: maxLength,
          keyboardType: keyboard,
          textCapitalization: caps,
          inputFormatters: inputFormatters,
          style: AppTheme.body(size: 15),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle:
                AppTheme.body(size: 15, color: AppColors.outlineVariant),
            filled: true,
            fillColor: enabled
                ? AppColors.surfaceContainerLow
                : AppColors.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _roleChip(String value, String label) {
    final active = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTheme.body(
            size: 13,
            weight: FontWeight.w600,
            color: active ? Colors.white : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
