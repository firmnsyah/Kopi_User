import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/connectivity.dart';
import '../utils/formatters.dart';
import '../widgets/app_toast.dart';

class InputScreen extends StatefulWidget {
  final Transaction? existing;
  const InputScreen({super.key, this.existing});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  late TxType _type;
  late String _method;
  String _category = '';
  bool _saving = false;
  bool _buktiCleared = false;

  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late final List<Product> _products =
      defaultProducts.map((p) => Product(name: p.$1, price: p.$2)).toList();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex == null) {
      _type = TxType.income;
      _method = 'QRIS';
    } else {
      _type = ex.type;
      _method = ex.method.isEmpty ? 'QRIS' : ex.method;
      _category = ex.type == TxType.expense ? ex.category : '';
      if (ex.type == TxType.expense) {
        _amountCtrl.text = formatRupiah(ex.amount).replaceFirst('Rp ', ' ');
      } else {
        for (final m in RegExp(r'(\d+)x\s+([^,]+)').allMatches(ex.category)) {
          final qty = int.tryParse(m.group(1) ?? '') ?? 0;
          final name = (m.group(2) ?? '').trim();
          final p = _products.firstWhere(
            (p) => p.name.toLowerCase() == name.toLowerCase(),
            orElse: () => Product(name: '', price: 0),
          );
          if (p.name.isNotEmpty) p.qty = qty;
        }
      }
      _notesCtrl.text = ex.notes == '-' ? '' : ex.notes;
      _buktiPath = ex.buktiPath;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _incomeTotal {
    return _products.fold(0, (s, p) => s + p.price * p.qty);
  }

  String get _orderSummary {
    return _products
        .where((p) => p.qty > 0)
        .map((p) => '${p.qty}x ${p.name}')
        .join(', ');
  }

  int get _amountValue {
    final raw = _amountCtrl.text.replaceAll(RegExp(r'\D'), '');
    return raw.isEmpty ? 0 : int.parse(raw);
  }

  String? _buktiPath;

  bool get _showBuktiSection => true;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final f = await picker.pickImage(source: source, imageQuality: 75);
      if (f != null) {
        setState(() {
          _buktiPath = f.path;
          _buktiCleared = false;
        });
      }
    } catch (e) {
      if (mounted) showAppToast(context, 'Gagal ambil gambar: $e', error: true);
    }
  }

  bool _isRemoteUrl(String path) =>
      path.startsWith('http') || path.startsWith('/uploads');

  Widget _brokenImageBox() => Container(
        height: 180,
        color: AppColors.surfaceContainer,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, size: 32),
      );

  Future<void> _submit() async {
    int amount;
    String category;
    String notes;

    if (_type == TxType.income) {
      amount = _incomeTotal;
      category = _orderSummary;
      notes = _notesCtrl.text.trim();
      if (amount <= 0) {
        showAppToast(context, 'Pilih minimal 1 produk', error: true);
        return;
      }
    } else {
      amount = _amountValue;
      category = _category;
      notes = _notesCtrl.text.trim();
      if (amount <= 0) {
        showAppToast(context, 'Masukkan jumlah transaksi', error: true);
        return;
      }
      if (category.isEmpty) {
        showAppToast(context, 'Pilih kategori terlebih dahulu', error: true);
        return;
      }
    }

    final online = await hasConnection();
    if (!mounted) return;
    if (!online) {
      showAppToast(context, 'Tidak ada koneksi internet', error: true);
      return;
    }

    setState(() => _saving = true);
    final repo = context.read<Repository>();
    final ex = widget.existing;
    final res = ex == null
        ? await repo.saveTransaction(
            type: _type,
            amount: amount,
            category: category,
            method: _method,
            notes: notes,
            buktiPath: _showBuktiSection ? _buktiPath : null,
          )
        : await repo.updateTransaction(
            id: ex.id,
            type: _type,
            amount: amount,
            category: category,
            method: _method,
            notes: notes,
            buktiPath: _showBuktiSection ? _buktiPath : null,
            clearBukti: _buktiCleared && _buktiPath == null,
          );
    if (!mounted) return;
    setState(() => _saving = false);

    if (res.success) {
      showAppToast(context, res.message);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop(res.tx);
    } else {
      showAppToast(context, res.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            _topBar(),
            const SizedBox(height: 8),
            _typeToggle(),
            const SizedBox(height: 24),
            if (_type == TxType.income)
              _productsSection()
            else
              _expenseSection(),
            const SizedBox(height: 24),
            _methodSection(),
            const SizedBox(height: 24),
            _buktiSection(),
            const SizedBox(height: 24),
            _notesSection(),
            const SizedBox(height: 32),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back,
                    color: AppColors.secondary, size: 24),
                const SizedBox(width: 8),
                Text('KEMBALI',
                    style:
                        AppTheme.label(size: 11, color: AppColors.secondary)),
              ],
            ),
          ),
          Text(_isEditing ? 'Edit Transaksi' : 'Catat Transaksi',
              style: AppTheme.headline(size: 18, color: AppColors.primary)),
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _typeToggle() {
    Widget btn(String label, IconData icon, TxType type) {
      final active = _type == type;
      final isIncome = type == TxType.income;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _type = type;
              _category = '';
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: active
                  ? (isIncome ? AppColors.primary : AppColors.error)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: active ? Colors.white : AppColors.secondary),
                const SizedBox(width: 6),
                Text(label,
                    style: AppTheme.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.secondary,
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          btn('Pemasukan', Icons.trending_up, TxType.income),
          btn('Pengeluaran', Icons.trending_down, TxType.expense),
        ],
      ),
    );
  }

  Widget _productsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PILIH PRODUK', style: AppTheme.label()),
        const SizedBox(height: 12),
        ...List.generate(_products.length, (i) => _productCard(i)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: AppTheme.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85))),
              Text(formatRupiah(_incomeTotal),
                  style: AppTheme.headline(
                    size: 22,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _productCard(int i) {
    final p = _products[i];
    final picked = p.qty > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: picked
              ? AppColors.primary
              : AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: AppTheme.body(size: 14, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(formatRupiah(p.price),
                    style: AppTheme.body(size: 12, color: AppColors.secondary)),
              ],
            ),
          ),
          _qtyBtn(picked ? '−' : '−', enabled: picked, onTap: () {
            setState(() => p.qty = (p.qty - 1).clamp(0, 999));
          }, isMinus: true),
          const SizedBox(width: 10),
          SizedBox(
            width: 24,
            child: Text('${p.qty}',
                textAlign: TextAlign.center,
                style: AppTheme.headline(
                  size: 18,
                  weight: FontWeight.w700,
                  color: picked ? AppColors.primary : AppColors.secondary,
                )),
          ),
          const SizedBox(width: 10),
          _qtyBtn('+', enabled: true, onTap: () {
            setState(() => p.qty++);
          }, isMinus: false),
        ],
      ),
    );
  }

  Widget _qtyBtn(String label,
      {required bool enabled,
      required VoidCallback onTap,
      required bool isMinus}) {
    Color bg;
    Color fg;
    if (isMinus) {
      bg = enabled
          ? AppColors.surfaceContainerHighest
          : AppColors.surfaceContainer;
      fg = enabled
          ? AppColors.primary
          : AppColors.secondary.withValues(alpha: 0.4);
    } else {
      bg = AppColors.primary;
      fg = Colors.white;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(label,
                style: AppTheme.body(
                  size: 18,
                  weight: FontWeight.w700,
                  color: fg,
                )),
          ),
        ),
      ),
    );
  }

  Widget _expenseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOMINAL', style: AppTheme.label()),
        const SizedBox(height: 8),
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          style: AppTheme.headline(size: 26, weight: FontWeight.w800),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandsFormatter(),
          ],
          decoration: InputDecoration(
            prefixText: 'Rp  ',
            prefixStyle: AppTheme.headline(
              size: 22,
              weight: FontWeight.w700,
              color: AppColors.secondary,
            ),
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('KATEGORI', style: AppTheme.label()),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: expenseCategories.map((c) {
            final active = _category == c;
            return GestureDetector(
              onTap: () => setState(() => _category = c),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(c,
                    style: AppTheme.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.secondary,
                    )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _methodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('METODE', style: AppTheme.label()),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: paymentMethods.map((m) {
            final active = _method == m;
            return GestureDetector(
              onTap: () => setState(() => _method = m),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(m,
                    style: AppTheme.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.secondary,
                    )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buktiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BUKTI PEMBAYARAN (OPSIONAL)', style: AppTheme.label()),
        const SizedBox(height: 12),
        if (_buktiPath != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isRemoteUrl(_buktiPath!)
                      ? Image.network(
                          _buktiPath!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _brokenImageBox(),
                        )
                      : Image.file(
                          File(_buktiPath!),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _brokenImageBox(),
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _buktiPath = null;
                      _buktiCleared = true;
                    }),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: _pickerBtn(
                  Icons.photo_camera,
                  'Kamera',
                  () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _pickerBtn(
                  Icons.image,
                  'Galeri',
                  () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _pickerBtn(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: AppTheme.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.secondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CATATAN (OPSIONAL)', style: AppTheme.label()),
        const SizedBox(height: 8),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          style: AppTheme.body(size: 14),
          decoration: InputDecoration(
            hintText: 'Tambahkan catatan...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
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
            onTap: _saving ? null : _submit,
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                            _isEditing
                                ? 'Simpan Perubahan'
                                : 'Simpan Transaksi',
                            style: AppTheme.headline(
                              size: 16,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            )),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (raw.isEmpty) return newValue.copyWith(text: '');
    final n = int.parse(raw);
    final formatted = formatRupiah(n).replaceFirst('Rp ', ' ');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
