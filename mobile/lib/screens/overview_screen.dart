import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/transaction.dart';
import '../state/session.dart' show AppSession;
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/connectivity.dart';
import '../utils/formatters.dart';
import '../widgets/app_toast.dart';
import '../widgets/filter_chip_widget.dart';
import 'employees_screen.dart';
import 'history_screen.dart';
import 'input_screen.dart';
import 'login_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  DashboardFilter _filter = DashboardFilter.today;
  DashboardData? _data;
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
    final repo = context.read<Repository>();
    final d = await repo.getDashboard(_filter);
    if (!mounted) return;
    setState(() {
      _data = d;
      _loading = false;
    });
  }

  void _setFilter(DashboardFilter f) {
    if (f == _filter) return;
    setState(() => _filter = f);
    _load();
  }

  Future<void> _logout() async {
    final online = await hasConnection();
    if (!mounted) return;
    if (!online) {
      showAppToast(context, 'Tidak ada koneksi internet', error: true);
      return;
    }
    await context.read<AppSession>().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _Fab(onTap: () async {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const InputScreen()));
        _load();
      }),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
            children: [
              _topBar(),
              const SizedBox(height: 8),
              _filters(),
              const SizedBox(height: 12),
              if (!context.watch<AppSession>().isAdmin)
                _staffBanner(),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_data != null) ...[
                _omzetCards(_data!),
                const SizedBox(height: 12),
                _profitCard(_data!),
                const SizedBox(height: 20),
                _distributionCard(_data!),
                const SizedBox(height: 20),
                _productSalesCard(_data!),
                const SizedBox(height: 20),
                _volumeCard(_data!),
                const SizedBox(height: 20),
                _expenseCard(_data!),
                const SizedBox(height: 28),
                _recentSection(_data!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _staffBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            'Menampilkan data transaksi kamu saja',
            style: AppTheme.label(size: 11, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/navbar_logo.png',
            height: 66,
          ),
          Row(
            children: [
              if (context.watch<AppSession>().isAdmin) ...[
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const EmployeesScreen()),
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(Icons.group,
                        color: AppColors.secondary, size: 24),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              GestureDetector(
                onTap: _logout,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child:
                      Icon(Icons.logout, color: AppColors.secondary, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          FilterChipBtn(
            label: 'Hari Ini',
            active: _filter == DashboardFilter.today,
            onTap: () => _setFilter(DashboardFilter.today),
          ),
          const SizedBox(width: 10),
          FilterChipBtn(
            label: 'Bulan Ini',
            active: _filter == DashboardFilter.month,
            onTap: () => _setFilter(DashboardFilter.month),
          ),
          const SizedBox(width: 10),
          FilterChipBtn(
            label: 'Keseluruhan',
            active: _filter == DashboardFilter.all,
            onTap: () => _setFilter(DashboardFilter.all),
          ),
        ],
      ),
    );
  }

  Widget _omzetCards(DashboardData d) {
    return Row(
      children: [
        Expanded(
            child: _summary('Pemasukan', d.totalIncome,
                gradient: AppColors.incomeGradient, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(
            child: _summary('Pengeluaran', d.totalExpense,
                gradient: AppColors.expenseGradient,
                color: const Color(0xFF3A3220))),
      ],
    );
  }

  Widget _summary(String label, int value,
      {required Gradient gradient, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTheme.label(
                  size: 11, color: color.withValues(alpha: 0.85))),
          const SizedBox(height: 8),
          Text(formatRupiah(value),
              style: AppTheme.headline(
                size: 20,
                weight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              )),
        ],
      ),
    );
  }

  Widget _profitCard(DashboardData d) {
    final profit = d.profit;
    final isLoss = profit < 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isLoss ? AppColors.lossGradient : AppColors.profitGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isLoss ? Icons.trending_down : Icons.trending_up,
                        size: 16, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text(isLoss ? 'RUGI' : 'PROFIT',
                        style: AppTheme.label(
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(formatRupiah(profit.abs()),
                    style: AppTheme.headline(
                      size: 26,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    )),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLoss ? Icons.warning : Icons.account_balance,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _distributionCard(DashboardData d) {
    final subtitle = switch (d.distributionMode) {
      'hourly' => 'Distribusi transaksi per jam',
      'daily' => 'Distribusi transaksi per hari',
      _ => 'Distribusi transaksi per bulan',
    };
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle,
              style: AppTheme.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.secondary)),
          const SizedBox(height: 24),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(d.chartBars.length, (i) {
                final pct = d.chartBars[i].clamp(0, 100);
                final isActive = pct >= 60;
                final factor = pct == 0 ? 0.02 : pct / 100;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            content: Text(d.chartTooltips[i]),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ));
                      },
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        heightFactor: 1,
                        child: FractionallySizedBox(
                          heightFactor: factor,
                          widthFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? AppColors.chartBarActiveGradient
                                  : AppColors.chartBarGradient,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                                bottom: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          _xLabels(d),
        ],
      ),
    );
  }

  Widget _xLabels(DashboardData d) {
    final cols = d.chartBars.length;
    final labelByPos = {for (final x in d.chartXLabels) x.pos: x.label};
    return Row(
      children: List.generate(cols, (i) {
        final lbl = labelByPos[i + 1] ?? '';
        return Expanded(
          child: Container(
            height: 16,
            alignment: Alignment.center,
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Text(
                lbl,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: AppTheme.label(size: 9, color: AppColors.secondary),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _hBar({
    required double fraction,
    required List<Color> colors,
    double height = 8,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.surfaceContainerHighest),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                heightFactor: 1.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productSalesCard(DashboardData d) {
    final entries = d.productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxQty = entries.isEmpty ? 1 : entries.first.value;
    const palette = [
      [Color(0xFF223628), Color(0xFF3A8F52)],
      [Color(0xFF492B08), Color(0xFFA0845C)],
      [Color(0xFF1A5276), Color(0xFF5DADE2)],
      [Color(0xFF77574D), Color(0xFFB08A7E)],
      [Color(0xFFC3C8C1), Color(0xFFA0A5A0)],
    ];

    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produk Terlaris', style: AppTheme.headline(size: 16)),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Belum ada penjualan',
                  style: AppTheme.body(color: AppColors.secondary)),
            )
          else
            ...List.generate(entries.length, (i) {
              final e = entries[i];
              final w = e.value / maxQty;
              final colors = palette[i % palette.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${i + 1}',
                              style: AppTheme.headline(
                                size: 11,
                                weight: FontWeight.w800,
                                color: AppColors.primary,
                              )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(e.key,
                              style: AppTheme.body(
                                  size: 13, weight: FontWeight.w600)),
                        ),
                        Text('${e.value} pcs',
                            style: AppTheme.headline(
                                size: 13, weight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _hBar(fraction: w, colors: colors),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _volumeCard(DashboardData d) {
    final v = d.volume;
    final total = (v['total'] ?? 0);
    final qris = v['qris'] ?? 0;
    final tunai = v['tunai'] ?? 0;
    final transfer = v['transfer'] ?? 0;
    double pct(int x) => total == 0 ? 0 : x / total;

    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Volume Transaksi', style: AppTheme.headline(size: 16)),
          const SizedBox(height: 16),
          _volumeRow(Icons.qr_code_2, AppColors.primary, 'QRIS', qris,
              pct(qris), const [Color(0xFF223628), Color(0xFF3A8F52)]),
          _volumeRow(Icons.payments, AppColors.tertiary, 'Tunai', tunai,
              pct(tunai), const [Color(0xFFA0845C), Color(0xFFC4A97A)]),
          _volumeRow(
              Icons.sync_alt,
              AppColors.secondary,
              'Transfer',
              transfer,
              pct(transfer),
              const [Color(0xFF494949), Color(0xFF888888)]),
        ],
      ),
    );
  }

  Widget _volumeRow(IconData icon, Color iconColor, String name, int count,
      double percent, List<Color> barColors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style:
                            AppTheme.body(size: 13, weight: FontWeight.w600)),
                    Text('$count transaksi',
                        style: AppTheme.body(
                            size: 11, color: AppColors.secondary)),
                  ],
                ),
              ),
              Text('${(percent * 100).toStringAsFixed(0)}%',
                  style: AppTheme.headline(size: 16, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          _hBar(fraction: percent, colors: barColors),
        ],
      ),
    );
  }

  Widget _expenseCard(DashboardData d) {
    final ec = d.expenseCats;
    final total = d.totalExpense;
    Widget row(IconData icon, Color color, String name, int amount,
        List<Color> barColors) {
      final w = total > 0 ? amount / total : 0.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name,
                      style: AppTheme.body(size: 13, weight: FontWeight.w600)),
                ),
                Text(formatRupiah(amount),
                    style:
                        AppTheme.headline(size: 13, weight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            _hBar(fraction: w, colors: barColors),
          ],
        ),
      );
    }

    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengeluaran', style: AppTheme.headline(size: 16)),
          const SizedBox(height: 16),
          row(
              Icons.inventory_2,
              AppColors.primary,
              'Bahan Baku',
              ec['Bahan Baku'] ?? 0,
              const [Color(0xFF223628), Color(0xFF3A8F52)]),
          row(
              Icons.bolt,
              AppColors.tertiary,
              'Operasional',
              ec['Operasional'] ?? 0,
              const [Color(0xFF492B08), Color(0xFFA0845C)]),
          row(
              Icons.group,
              AppColors.secondary,
              'Gaji Staff',
              ec['Gaji Staff'] ?? 0,
              const [Color(0xFF77574D), Color(0xFFB08A7E)]),
          row(
              Icons.more_horiz,
              AppColors.outlineVariant,
              'Lain-lain',
              ec['Lain-lain'] ?? 0,
              const [Color(0xFFC3C8C1), Color(0xFFA0A5A0)]),
        ],
      ),
    );
  }

  Widget _recentSection(DashboardData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Riwayat Transaksi', style: AppTheme.headline(size: 16)),
                const SizedBox(height: 4),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()));
              },
              child: Text('View All',
                  style: AppTheme.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 2.5,
                  ).copyWith(decoration: TextDecoration.underline)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _RecentHeader(),
        if (d.recent.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text('Belum ada transaksi',
                  style: AppTheme.body(color: AppColors.secondary)),
            ),
          )
        else
          ...d.recent.map((t) => _recentRow(t)),
      ],
    );
  }

  Widget _recentRow(Transaction t) {
    final isIncome = t.type == TxType.income;
    final method = t.method.toUpperCase();
    final (badgeBg, badgeFg) = switch (method) {
      'QRIS' => (const Color(0xFFDFF0D8), AppColors.primary),
      'TUNAI' => (const Color(0xFFF0E4D0), AppColors.tertiary),
      _ => (const Color(0xFF494949), Colors.white),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(t.id,
                style: AppTheme.body(size: 13, weight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(formatTimeHM(t.createdAt),
                textAlign: TextAlign.center,
                style: AppTheme.body(size: 13, color: AppColors.secondary)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${formatRupiah(t.amount)}',
                  style: AppTheme.headline(
                    size: 13,
                    weight: FontWeight.w700,
                    color: isIncome ? AppColors.primary : AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(method,
                      style: AppTheme.label(
                        size: 9,
                        color: badgeFg,
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text('ID TRANSAKSI', style: AppTheme.label())),
          Expanded(
              child: Text('WAKTU',
                  textAlign: TextAlign.center, style: AppTheme.label())),
          Expanded(
              child: Text('INFO',
                  textAlign: TextAlign.right, style: AppTheme.label())),
        ],
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryButtonGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59223628),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
