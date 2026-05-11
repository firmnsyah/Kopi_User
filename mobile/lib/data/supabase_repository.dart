import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'repository.dart';

class SupabaseRepository implements Repository {
  SupabaseClient get _db => Supabase.instance.client;

  // ── Auth ─────────────────────────────────────────────────────────────────

  @override
  Future<({bool success, String? employeeId, String? role, String? token, String message})>
      clockIn(String employeeId, String pin) async {
    try {
      final res = await _db.auth.signInWithPassword(
        email: '${employeeId.trim().toLowerCase()}@kopi.local',
        password: pin.trim(),
      );
      final meta = res.user?.userMetadata;
      final id = meta?['employee_id'] as String? ?? employeeId.toUpperCase();
      final name = meta?['name'] as String? ?? id;
      final role = meta?['role'] as String? ?? 'staff';

      // Cek apakah karyawan masih aktif
      final emp = await _db
          .from('employees')
          .select('active')
          .eq('employee_id', id)
          .maybeSingle();
      if (emp != null && emp['active'] == false) {
        await _db.auth.signOut();
        return (
          success: false,
          employeeId: null,
          role: null,
          token: null,
          message: 'Akun karyawan ini sudah dinonaktifkan.',
        );
      }

      return (
        success: true,
        employeeId: id,
        role: role,
        token: res.session?.accessToken,
        message: 'Selamat bekerja, $name.',
      );
    } on AuthException {
      return (
        success: false,
        employeeId: null,
        role: null,
        token: null,
        message: 'ID atau PIN salah. Silakan coba lagi.',
      );
    } catch (_) {
      return (
        success: false,
        employeeId: null,
        role: null,
        token: null,
        message: 'Tidak dapat terhubung ke server.',
      );
    }
  }

  // ── File upload ───────────────────────────────────────────────────────────

  Future<String?> _uploadBukti(String localPath) async {
    try {
      final file = File(localPath);
      final ext = localPath.split('.').last.toLowerCase();
      final name = '${DateTime.now().millisecondsSinceEpoch}_'
          '${Random().nextInt(9999)}.$ext';
      await _db.storage
          .from('bukti')
          .upload(name, file, fileOptions: const FileOptions(upsert: false));
      return _db.storage.from('bukti').getPublicUrl(name);
    } catch (_) {
      return null;
    }
  }

  // Returns buktiUrl to store; handles local file vs existing URL.
  Future<String?> _resolveBukti(String? path, bool clear) async {
    if (clear || path == null) return null;
    if (path.startsWith('http') || path.startsWith('/')) return path;
    return _uploadBukti(path);
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  @override
  Future<({bool success, String message, Transaction? tx})> saveTransaction({
    required TxType type,
    required int amount,
    required String category,
    required String method,
    required String notes,
    String? buktiPath,
  }) async {
    final buktiUrl = await _resolveBukti(buktiPath, false);
    final employeeId =
        _db.auth.currentUser?.userMetadata?['employee_id'] as String? ?? '';

    final row = await _db
        .from('transactions')
        .insert({
          'type': type.name,
          'amount': amount,
          'category': category,
          'method': method,
          'notes': notes,
          if (buktiUrl != null) 'bukti_url': buktiUrl,
          'employee_id': employeeId,
        })
        .select()
        .single();

    final tx = Transaction.fromJson(row);
    final label = type == TxType.income ? 'Pemasukan' : 'Pengeluaran';
    return (
      success: true,
      message: '$label sebesar ${formatRupiah(amount)} berhasil dicatat!',
      tx: tx,
    );
  }

  @override
  Future<({bool success, String message, Transaction? tx})> updateTransaction({
    required String id,
    required TxType type,
    required int amount,
    required String category,
    required String method,
    required String notes,
    String? buktiPath,
    bool clearBukti = false,
  }) async {
    final buktiUrl = await _resolveBukti(buktiPath, clearBukti);

    final row = await _db
        .from('transactions')
        .update({
          'type': type.name,
          'amount': amount,
          'category': category,
          'method': method,
          'notes': notes,
          'bukti_url': buktiUrl,
        })
        .eq('tx_id', id)
        .select()
        .single();

    return (
      success: true,
      message: 'Transaksi berhasil diperbarui.',
      tx: Transaction.fromJson(row),
    );
  }

  @override
  Future<({bool success, String message})> deleteTransaction(String id) async {
    await _db.from('transactions').delete().eq('tx_id', id);
    return (success: true, message: 'Transaksi berhasil dihapus.');
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  @override
  Future<DashboardData> getDashboard(DashboardFilter filter) async {
    final now = DateTime.now();

    PostgrestFilterBuilder<List<Map<String, dynamic>>> q =
        _db.from('transactions').select();

    if (filter == DashboardFilter.today) {
      final s = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final e = DateTime(now.year, now.month, now.day + 1).toUtc().toIso8601String();
      q = q.gte('created_at', s).lt('created_at', e);
    } else if (filter == DashboardFilter.month) {
      final s = DateTime(now.year, now.month, 1).toUtc().toIso8601String();
      final e = DateTime(now.year, now.month + 1, 1).toUtc().toIso8601String();
      q = q.gte('created_at', s).lt('created_at', e);
    }

    final rows = await q.order('created_at', ascending: false);
    final txs = rows.map((r) => Transaction.fromJson(r)).toList();
    return _computeDashboard(txs, filter, now);
  }

  // ── History ───────────────────────────────────────────────────────────────

  @override
  Future<List<Transaction>> getDetailedHistory(HistoryQuery query) async {
    final now = DateTime.now();

    PostgrestFilterBuilder<List<Map<String, dynamic>>> q =
        _db.from('transactions').select();

    if (query.mode == HistoryFilter.today) {
      final s = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final e = DateTime(now.year, now.month, now.day + 1).toUtc().toIso8601String();
      q = q.gte('created_at', s).lt('created_at', e);
    } else if (query.mode == HistoryFilter.month) {
      final s = DateTime(now.year, now.month, 1).toUtc().toIso8601String();
      final e = DateTime(now.year, now.month + 1, 1).toUtc().toIso8601String();
      q = q.gte('created_at', s).lt('created_at', e);
    } else if (query.mode == HistoryFilter.custom &&
        query.start != null &&
        query.end != null) {
      final s =
          DateTime(query.start!.year, query.start!.month, query.start!.day)
              .toUtc()
              .toIso8601String();
      final e = DateTime(
              query.end!.year, query.end!.month, query.end!.day, 23, 59, 59)
          .toUtc()
          .toIso8601String();
      q = q.gte('created_at', s).lte('created_at', e);
    }

    if (query.type != null) {
      q = q.eq('type', query.type!.name);
    }

    final rows = await q.order('created_at', ascending: false);
    return rows.map((r) => Transaction.fromJson(r)).toList();
  }

  // ── Employee management ───────────────────────────────────────────────────

  @override
  Future<List<Employee>> getEmployees() async {
    final rows = await _db
        .from('employees')
        .select()
        .order('created_at', ascending: true);
    return rows.map((r) => Employee.fromJson(r)).toList();
  }

  @override
  Future<({bool success, String message})> createEmployee({
    required String employeeId,
    required String name,
    required String role,
    required String pin,
  }) async {
    try {
      final res = await _db.rpc('admin_create_employee', params: {
        'p_employee_id': employeeId.trim().toUpperCase(),
        'p_name': name.trim(),
        'p_role': role,
        'p_pin': pin,
      });
      final ok = res['success'] == true;
      return (
        success: ok,
        message: ok
            ? 'Karyawan berhasil ditambahkan.'
            : (res['error'] as String? ?? 'Gagal menambahkan karyawan.'),
      );
    } catch (_) {
      return (success: false, message: 'Tidak dapat terhubung ke server.');
    }
  }

  @override
  Future<({bool success, String message})> updateEmployee({
    required String employeeId,
    required String name,
    required String role,
    String? newPin,
  }) async {
    try {
      final res = await _db.rpc('admin_update_employee', params: {
        'p_employee_id': employeeId,
        'p_name': name.trim(),
        'p_role': role,
        'p_new_pin': newPin,
      });
      final ok = res['success'] == true;
      return (
        success: ok,
        message: ok
            ? 'Data karyawan berhasil diperbarui.'
            : (res['error'] as String? ?? 'Gagal memperbarui karyawan.'),
      );
    } catch (_) {
      return (success: false, message: 'Tidak dapat terhubung ke server.');
    }
  }

  @override
  Future<({bool success, String message})> toggleEmployeeActive(
      String employeeId) async {
    try {
      final res = await _db.rpc('admin_toggle_employee', params: {
        'p_employee_id': employeeId,
      });
      final ok = res['success'] == true;
      final nowActive = res['active'] == true;
      return (
        success: ok,
        message: ok
            ? 'Karyawan berhasil ${nowActive ? 'diaktifkan' : 'dinonaktifkan'}.'
            : (res['error'] as String? ?? 'Gagal mengubah status karyawan.'),
      );
    } catch (_) {
      return (success: false, message: 'Tidak dapat terhubung ke server.');
    }
  }

  // ── Dashboard computation (same logic as mock) ────────────────────────────

  static DashboardData _computeDashboard(
      List<Transaction> txs, DashboardFilter filter, DateTime now) {
    final mode = switch (filter) {
      DashboardFilter.today => 'hourly',
      DashboardFilter.month => 'daily',
      DashboardFilter.all => 'monthly',
    };
    final distSize = switch (filter) {
      DashboardFilter.today => 24,
      DashboardFilter.month => 31,
      DashboardFilter.all => 12,
    };

    int totalIncome = 0, totalExpense = 0;
    int qris = 0, tunai = 0, transfer = 0;
    final cats = <String, int>{
      'Bahan Baku': 0,
      'Operasional': 0,
      'Gaji Staff': 0,
      'Lain-lain': 0,
    };
    final productSales = <String, int>{};
    final distRaw = List<int>.filled(distSize, 0);
    final productPattern = RegExp(r'(\d+)x\s+([^,]+)');

    for (final t in txs) {
      if (t.type == TxType.income) {
        totalIncome += t.amount;
        switch (t.method.toUpperCase()) {
          case 'QRIS':
            qris++;
            break;
          case 'TUNAI':
            tunai++;
            break;
          case 'TRANSFER':
            transfer++;
            break;
        }
        for (final m in productPattern.allMatches(t.category)) {
          final qty = int.tryParse(m.group(1) ?? '') ?? 0;
          final name = (m.group(2) ?? '').trim();
          if (qty > 0 && name.isNotEmpty) {
            productSales[name] = (productSales[name] ?? 0) + qty;
          }
        }
        if (mode == 'hourly') {
          distRaw[t.createdAt.hour]++;
        } else if (mode == 'daily') {
          distRaw[t.createdAt.day - 1]++;
        } else {
          distRaw[t.createdAt.month - 1]++;
        }
      } else {
        totalExpense += t.amount;
        final cat = cats.containsKey(t.category) ? t.category : 'Lain-lain';
        cats[cat] = cats[cat]! + t.amount;
      }
    }

    final maxV = distRaw.fold<int>(1, (p, c) => c > p ? c : p);
    final bars = distRaw.map((v) => ((v / maxV) * 100).floor()).toList();

    final tooltips = <String>[];
    final xLabels = <({String label, int pos})>[];

    if (mode == 'hourly') {
      for (int i = 0; i < 24; i++) {
        tooltips.add('${i.toString().padLeft(2, '0')}:00 : ${distRaw[i]} Trx');
      }
      xLabels.addAll([
        (label: '00', pos: 1),
        (label: '04', pos: 5),
        (label: '08', pos: 9),
        (label: '12', pos: 13),
        (label: '16', pos: 17),
        (label: '20', pos: 21),
        (label: '24', pos: 24),
      ]);
    } else if (mode == 'daily') {
      for (int i = 0; i < 31; i++) {
        tooltips.add(
            'Tgl ${i + 1} ${monthNames[now.month - 1]} : ${distRaw[i]} Trx');
      }
      xLabels.addAll([
        (label: '01', pos: 1),
        (label: '10', pos: 10),
        (label: '20', pos: 20),
        (label: '31', pos: 31),
      ]);
    } else {
      for (int i = 0; i < 12; i++) {
        tooltips.add('Bulan ${monthNames[i]} : ${distRaw[i]} Trx');
      }
      xLabels.addAll([
        (label: 'Jan', pos: 1),
        (label: 'Apr', pos: 4),
        (label: 'Jul', pos: 7),
        (label: 'Okt', pos: 10),
        (label: 'Des', pos: 12),
      ]);
    }

    return DashboardData(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      volume: {
        'qris': qris,
        'tunai': tunai,
        'transfer': transfer,
        'total': qris + tunai + transfer
      },
      expenseCats: cats,
      productSales: productSales,
      distributionMode: mode,
      chartBars: bars,
      chartTooltips: tooltips,
      chartXLabels: xLabels,
      recent: txs.take(5).toList(),
    );
  }
}
