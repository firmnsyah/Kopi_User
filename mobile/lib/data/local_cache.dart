import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import 'repository.dart';

/// Menyimpan salinan data terakhir dari server ke SharedPreferences agar tetap
/// bisa ditampilkan saat aplikasi tidak terhubung ke jaringan.
class LocalCache {
  LocalCache._();

  static String _dashKey(DashboardFilter f) => 'cache_dashboard_${f.name}';
  static String _historyKey(HistoryFilter f, TxType? t) =>
      'cache_history_${f.name}_${t?.name ?? 'all'}';

  // ── Dashboard ───────────────────────────────────────────────────────────────
  static Future<void> saveDashboard(
      DashboardFilter filter, DashboardData data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_dashKey(filter), jsonEncode(data.toJson()));
  }

  static Future<DashboardData?> loadDashboard(DashboardFilter filter) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_dashKey(filter));
    if (raw == null) return null;
    try {
      return DashboardData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── History ──────────────────────────────────────────────────────────────────
  // Mode 'custom' (rentang tanggal bebas) tidak di-cache.
  static Future<void> saveHistory(
      HistoryFilter filter, TxType? type, List<Transaction> txs) async {
    if (filter == HistoryFilter.custom) return;
    final p = await SharedPreferences.getInstance();
    final list = txs.map((t) => t.toJson()).toList();
    await p.setString(_historyKey(filter, type), jsonEncode(list));
  }

  static Future<List<Transaction>?> loadHistory(
      HistoryFilter filter, TxType? type) async {
    if (filter == HistoryFilter.custom) return null;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_historyKey(filter, type));
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
