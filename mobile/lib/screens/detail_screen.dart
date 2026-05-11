import 'dart:io';
import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'input_screen.dart';

class DetailScreen extends StatefulWidget {
  final Transaction tx;
  const DetailScreen({super.key, required this.tx});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Transaction tx = widget.tx;

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<Transaction?>(
      MaterialPageRoute(builder: (_) => InputScreen(existing: tx)),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() => tx = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TxType.income;
    final method = tx.method.toUpperCase();
    final (badgeBg, badgeFg) = switch (method) {
      'QRIS' => (const Color(0xFFDFF0D8), AppColors.primary),
      'TUNAI' => (const Color(0xFFF0E4D0), AppColors.tertiary),
      _ => (const Color(0xFF494949), Colors.white),
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back,
                          color: AppColors.secondary, size: 22),
                      const SizedBox(width: 8),
                      Text('KEMBALI KE RIWAYAT',
                          style: AppTheme.label(
                              size: 11, color: AppColors.secondary)),
                    ],
                  ),
                ),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _openEdit,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.edit,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text('EDIT',
                              style: AppTheme.label(
                                  size: 10, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _mainCard(isIncome, badgeBg, badgeFg, method),
            if (tx.buktiPath != null) ...[
              const SizedBox(height: 20),
              _buktiCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mainCard(bool isIncome, Color badgeBg, Color badgeFg, String method) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tx.id,
                  style: AppTheme.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.secondary)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(method,
                    style: AppTheme.label(size: 10, color: badgeFg)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('NOMINAL TRANSAKSI', style: AppTheme.label()),
          const SizedBox(height: 6),
          Text('${isIncome ? '+' : '-'}${formatRupiah(tx.amount)}',
              style: AppTheme.headline(
                size: 32,
                weight: FontWeight.w900,
                color: isIncome ? AppColors.primary : AppColors.error,
                letterSpacing: -1,
              )),
          const SizedBox(height: 24),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _kv('TIPE', tx.tipeLabel)),
              const SizedBox(width: 16),
              Expanded(
                  child: _kv(
                      'KATEGORI', tx.category.isEmpty ? '-' : tx.category)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _kv('TANGGAL', formatDateDMY(tx.createdAt))),
              const SizedBox(width: 16),
              Expanded(child: _kv('WAKTU', formatTimeHM(tx.createdAt))),
            ],
          ),
          if (tx.notes.isNotEmpty && tx.notes != '-') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.description,
                    size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text('CATATAN', style: AppTheme.label()),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Text(tx.notes,
                  style: AppTheme.body(
                      size: 13,
                      color: AppColors.onSurface,
                      weight: FontWeight.w400)
                  .copyWith(fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.label()),
        const SizedBox(height: 4),
        Text(value,
            style: AppTheme.body(size: 14, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buktiCard() {
    final path = tx.buktiPath!;
    final isUrl = path.startsWith('http');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, size: 14, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text('BUKTI PEMBAYARAN', style: AppTheme.label()),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isUrl
                ? Image.network(
                    path,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buktiPlaceholder(),
                  )
                : Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buktiPlaceholder(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buktiPlaceholder() {
    return Container(
      height: 200,
      color: AppColors.surfaceContainerLow,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Versi pratinjau tidak tersedia',
            textAlign: TextAlign.center,
            style: AppTheme.body(size: 12, color: AppColors.secondary)
                .copyWith(fontStyle: FontStyle.italic)),
      ),
    );
  }
}
