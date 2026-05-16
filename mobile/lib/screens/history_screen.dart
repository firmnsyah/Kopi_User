import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/transaction.dart';
import '../state/session.dart' show AppSession;
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/pdf_export.dart';
import '../widgets/app_toast.dart';
import '../widgets/filter_chip_widget.dart';
import 'detail_screen.dart';
import 'input_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _filter = HistoryFilter.today;
  TxType? _typeFilter;
  bool _customOpen = false;
  DateTime? _customStart;
  DateTime? _customEnd;

  List<Transaction>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = context.read<Repository>();
    final r = await repo.getDetailedHistory(HistoryQuery(
      mode: _filter,
      start: _customStart,
      end: _customEnd,
      type: _typeFilter,
    ));
    if (!mounted) return;
    setState(() {
      _data = r;
      _loading = false;
    });
  }

  void _setTypeFilter(TxType? t) {
    if (t == _typeFilter) return;
    setState(() => _typeFilter = t);
    _load();
  }

  void _setFilter(HistoryFilter f) {
    setState(() {
      _filter = f;
      if (f != HistoryFilter.custom) _customOpen = false;
    });
    if (f != HistoryFilter.custom) _load();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_customStart ?? DateTime.now())
        : (_customEnd ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStart = picked;
        } else {
          _customEnd = picked;
        }
      });
    }
  }

  String _groupKey(DateTime d) {
    switch (_filter) {
      case HistoryFilter.today:
        return '${d.hour.toString().padLeft(2, '0')}:00';
      case HistoryFilter.month:
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
      case HistoryFilter.all:
        return '${monthNames[d.month - 1]} ${d.year}';
      case HistoryFilter.custom:
        return formatDateDMY(d);
    }
  }

  String _groupLabel(String key) {
    switch (_filter) {
      case HistoryFilter.today:
        return 'Pukul $key';
      case HistoryFilter.month:
        return 'Tanggal $key';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Transaction>>{};
    if (_data != null) {
      for (final t in _data!) {
        groups.putIfAbsent(_groupKey(t.createdAt), () => []).add(t);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topBar(),
            if (!context.watch<AppSession>().isAdmin)
              _staffBanner(),
            const SizedBox(height: 4),
            _filters(),
            if (_customOpen) _customDateBox(),
            const SizedBox(height: 8),
            _typeFilters(),
            const SizedBox(height: 8),
            _listHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _data == null || _data!.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('Tidak ada transaksi pada periode ini',
                                textAlign: TextAlign.center,
                                style:
                                    AppTheme.body(color: AppColors.secondary)),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            children: [
                              for (final entry in groups.entries) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 16, bottom: 8),
                                  child: Text(_groupLabel(entry.key),
                                      style: AppTheme.label(
                                        size: 11,
                                        color: AppColors.secondary,
                                      )),
                                ),
                                ...entry.value.map((t) => _row(t)),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _staffBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded,
              size: 15, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(
            'Menampilkan transaksi yang kamu input saja',
            style: AppTheme.label(size: 11, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    final canExport = _data != null && !_loading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Row(
              children: [
                Icon(Icons.arrow_back,
                    color: AppColors.secondary, size: 24),
                SizedBox(width: 8),
              ],
            ),
          ),
          Text('Riwayat Transaksi',
              style: AppTheme.headline(size: 16, color: AppColors.primary)),
          GestureDetector(
            onTap: canExport ? _exportPdf : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Icon(Icons.picture_as_pdf,
                  color:
                      canExport ? AppColors.primary : AppColors.outlineVariant,
                  size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_data == null) return;
    try {
      await PdfExport.shareHistoryAsPdf(
        filter: _filter,
        transactions: _data!,
        customStart: _customStart,
        customEnd: _customEnd,
      );
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Gagal export PDF: $e', error: true);
      }
    }
  }

  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          FilterChipBtn(
            label: 'Hari Ini',
            active: _filter == HistoryFilter.today,
            onTap: () => _setFilter(HistoryFilter.today),
          ),
          const SizedBox(width: 8),
          FilterChipBtn(
            label: 'Bulan Ini',
            active: _filter == HistoryFilter.month,
            onTap: () => _setFilter(HistoryFilter.month),
          ),
          const SizedBox(width: 8),
          FilterChipBtn(
            label: 'Keseluruhan',
            active: _filter == HistoryFilter.all,
            onTap: () => _setFilter(HistoryFilter.all),
          ),
          const SizedBox(width: 8),
          FilterChipBtn(
            label: 'Custom',
            active: _filter == HistoryFilter.custom,
            onTap: () {
              setState(() {
                _filter = HistoryFilter.custom;
                _customOpen = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _typeFilters() {
    Widget chip(String label, TxType? value, IconData? icon, Color? activeBg) {
      final active = _typeFilter == value;
      final bg = active ? (activeBg ?? AppColors.primary) : Colors.white;
      final fg = active ? Colors.white : AppColors.secondary;
      return GestureDetector(
        onTap: () => _setTypeFilter(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: active
                  ? Colors.transparent
                  : AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: AppTheme.body(
                      size: 12, weight: FontWeight.w600, color: fg)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          chip('Semua', null, null, null),
          const SizedBox(width: 8),
          chip('Pemasukan', TxType.income, Icons.trending_up,
              AppColors.primary),
          const SizedBox(width: 8),
          chip('Pengeluaran', TxType.expense, Icons.trending_down,
              AppColors.error),
        ],
      ),
    );
  }

  Widget _customDateBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _dateField('MULAI', _customStart, isStart: true)),
              const SizedBox(width: 12),
              Expanded(child: _dateField('SAMPAI', _customEnd, isStart: false)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed:
                  (_customStart != null && _customEnd != null) ? _load : null,
              child: Text('TERAPKAN FILTER',
                  style: AppTheme.label(size: 11, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, {required bool isStart}) {
    return GestureDetector(
      onTap: () => _pickDate(isStart: isStart),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.label(size: 10, color: AppColors.secondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Text(value == null ? '— pilih —' : formatDateDMY(value),
                style: AppTheme.body(size: 13)),
          ),
        ],
      ),
    );
  }

  Widget _listHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text('ID', style: AppTheme.label())),
          Expanded(
              child: Text('WAKTU/TGL',
                  textAlign: TextAlign.center, style: AppTheme.label())),
          Expanded(
              child: Text('NOMINAL',
                  textAlign: TextAlign.right, style: AppTheme.label())),
        ],
      ),
    );
  }

  Widget _row(Transaction t) {
    final isIncome = t.type == TxType.income;
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailScreen(tx: t)),
        );
        if (mounted) _load();
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Kelola Transaksi ${t.id}',
                      style: AppTheme.headline(size: 16)),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.primary),
                  title: Text('Edit',
                      style: AppTheme.body(weight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => InputScreen(existing: t)),
                    );
                    if (mounted) _load();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: Text('Hapus',
                      style: AppTheme.body(
                          weight: FontWeight.w600, color: AppColors.error)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Hapus Transaksi?'),
                        content:
                            const Text('Tindakan ini tidak dapat dibatalkan.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Hapus',
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      final repo = context.read<Repository>();
                      final res = await repo.deleteTransaction(t.id);
                      if (mounted) {
                        showAppToast(context, res.message, error: !res.success);
                        if (res.success) _load();
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(t.id,
                  style: AppTheme.body(size: 12, weight: FontWeight.w600)),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(formatTimeHM(t.createdAt),
                      style: AppTheme.body(size: 12)),
                  Text(formatDateDMY(t.createdAt),
                      style:
                          AppTheme.body(size: 10, color: AppColors.secondary)),
                ],
              ),
            ),
            Expanded(
              child: Text(
                '${isIncome ? '+' : '-'}${formatRupiah(t.amount)}',
                textAlign: TextAlign.right,
                style: AppTheme.headline(
                  size: 13,
                  weight: FontWeight.w700,
                  color: isIncome ? AppColors.primary : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
