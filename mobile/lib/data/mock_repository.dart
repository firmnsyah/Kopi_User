import 'dart:math';
import '../models/employee.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'repository.dart';

class MockRepository implements Repository {
  final Map<String, String> _users = {
    'ROASTER-01': '1234',
    'BARISTA-01': '0000',
  };

  final List<Transaction> _txs = [];
  int _nextIdNumber = 1;

  // Track siapa yang sedang login
  String? _currentEmployeeId;
  String _currentRole = 'staff';

  MockRepository() {
    _seed();
  }

  bool get _isAdmin => _currentRole == 'admin';

  void _seed() {
    final now = DateTime.now();
    final rng = Random(42);
    final categories = ['Bahan Baku', 'Operasional', 'Gaji Staff', 'Lain-lain'];
    final methods = ['QRIS', 'Tunai', 'Transfer'];
    final products = [
      '1x Kopi Susu',
      '2x Kopi Gula Aren',
      '1x Coklat Susu',
      '3x Kopi Susu',
    ];
    // Distribusi transaksi: 65% ROASTER-01, 35% BARISTA-01
    final seedEmployees = ['ROASTER-01', 'ROASTER-01', 'BARISTA-01'];

    for (int day = 0; day < 14; day++) {
      final n = 3 + rng.nextInt(6);
      for (int i = 0; i < n; i++) {
        final t = now.subtract(Duration(
          days: day,
          hours: rng.nextInt(12),
          minutes: rng.nextInt(60),
        ));
        final empId = seedEmployees[rng.nextInt(seedEmployees.length)];
        final isIncome = rng.nextDouble() < 0.75;
        if (isIncome) {
          _txs.add(_make(
            type: TxType.income,
            amount: 10000 + rng.nextInt(5) * 5000,
            category: products[rng.nextInt(products.length)],
            method: methods[rng.nextInt(methods.length)],
            notes: '',
            createdAt: t,
            employeeId: empId,
          ));
        } else {
          _txs.add(_make(
            type: TxType.expense,
            amount: 25000 + rng.nextInt(20) * 5000,
            category: categories[rng.nextInt(categories.length)],
            method: methods[rng.nextInt(methods.length)],
            notes: 'Pengeluaran rutin',
            createdAt: t,
            employeeId: empId,
          ));
        }
      }
    }
    _txs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Transaction _make({
    required TxType type,
    required int amount,
    required String category,
    required String method,
    required String notes,
    required DateTime createdAt,
    String? buktiPath,
    String? employeeId,
  }) {
    final id = '#USR-${(98400 + _nextIdNumber).toString()}';
    _nextIdNumber++;
    return Transaction(
      id: id,
      type: type,
      amount: amount,
      category: category,
      method: method,
      notes: notes,
      createdAt: createdAt,
      buktiPath: buktiPath,
      employeeId: employeeId,
    );
  }

  // Terapkan filter role: admin lihat semua, staff hanya miliknya
  List<Transaction> _applyRoleFilter(List<Transaction> txs) {
    if (_isAdmin) return txs;
    return txs.where((t) => t.employeeId == _currentEmployeeId).toList();
  }

  @override
  Future<({bool success, String? employeeId, String? role, String? token, String message})> clockIn(
      String employeeId, String pin) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final id = employeeId.trim();
    final p = pin.trim();
    if (_users[id] == p) {
      _currentEmployeeId = id;
      final emp = _employees.firstWhere(
        (e) => e.employeeId == id,
        orElse: () => _employees.first,
      );
      _currentRole = emp.role;
      return (success: true, employeeId: id, role: emp.role, token: null, message: 'Selamat bekerja, $id.');
    }
    return (
      success: false,
      employeeId: null,
      role: null,
      token: null,
      message: 'ID atau PIN salah. Silakan coba lagi.'
    );
  }

  @override
  Future<({bool success, String message, Transaction? tx})> saveTransaction({
    required TxType type,
    required int amount,
    required String category,
    required String method,
    required String notes,
    String? buktiPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final tx = _make(
      type: type,
      amount: amount,
      category: category,
      method: method,
      notes: notes,
      createdAt: DateTime.now(),
      buktiPath: buktiPath,
      employeeId: _currentEmployeeId,
    );
    _txs.add(tx);
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
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _txs.indexWhere((t) => t.id == id);
    if (idx == -1) {
      return (success: false, message: 'Transaksi tidak ditemukan', tx: null);
    }
    final old = _txs[idx];
    // Staff hanya bisa edit miliknya sendiri
    if (!_isAdmin && old.employeeId != _currentEmployeeId) {
      return (success: false, message: 'Tidak punya akses ke transaksi ini.', tx: null);
    }
    final updated = Transaction(
      id: old.id,
      type: type,
      amount: amount,
      category: category,
      method: method,
      notes: notes,
      createdAt: old.createdAt,
      buktiPath: clearBukti ? null : (buktiPath ?? old.buktiPath),
      employeeId: old.employeeId,
    );
    _txs[idx] = updated;
    return (success: true, message: 'Transaksi berhasil diperbarui', tx: updated);
  }

  @override
  Future<({bool success, String message})> deleteTransaction(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _txs.indexWhere((t) => t.id == id);
    if (idx == -1) {
      return (success: false, message: 'Transaksi tidak ditemukan');
    }
    final t = _txs[idx];
    // Staff hanya bisa hapus miliknya sendiri
    if (!_isAdmin && t.employeeId != _currentEmployeeId) {
      return (success: false, message: 'Tidak punya akses ke transaksi ini.');
    }
    _txs.removeAt(idx);
    return (success: true, message: 'Transaksi berhasil dihapus');
  }

  @override
  Future<DashboardData> getDashboard(DashboardFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    bool includeByDate(Transaction t) {
      switch (filter) {
        case DashboardFilter.today:
          return isSameDay(t.createdAt, now);
        case DashboardFilter.month:
          return isSameMonth(t.createdAt, now);
        case DashboardFilter.all:
          return true;
      }
    }

    final filtered = _applyRoleFilter(_txs.where(includeByDate).toList())
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int totalIncome = 0, totalExpense = 0;
    int qris = 0, tunai = 0, transfer = 0;
    final cats = <String, int>{
      'Bahan Baku': 0,
      'Operasional': 0,
      'Gaji Staff': 0,
      'Lain-lain': 0,
    };
    final productSales = <String, int>{};
    final productPattern = RegExp(r'(\d+)x\s+([^,]+)');

    final distSize = switch (filter) {
      DashboardFilter.today => 24,
      DashboardFilter.month => 31,
      DashboardFilter.all => 12,
    };
    final distRaw = List<int>.filled(distSize, 0);

    for (final t in filtered) {
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
        switch (filter) {
          case DashboardFilter.today:
            distRaw[t.createdAt.hour]++;
            break;
          case DashboardFilter.month:
            distRaw[t.createdAt.day - 1]++;
            break;
          case DashboardFilter.all:
            distRaw[t.createdAt.month - 1]++;
            break;
        }
      } else {
        totalExpense += t.amount;
        if (cats.containsKey(t.category)) {
          cats[t.category] = cats[t.category]! + t.amount;
        } else {
          cats['Lain-lain'] = cats['Lain-lain']! + t.amount;
        }
      }
    }

    final maxV = distRaw.fold<int>(1, (p, c) => c > p ? c : p);
    final bars = distRaw.map((v) => ((v / maxV) * 100).floor()).toList();

    final mode = switch (filter) {
      DashboardFilter.today => 'hourly',
      DashboardFilter.month => 'daily',
      DashboardFilter.all => 'monthly',
    };

    final tooltips = <String>[];
    final xLabels = <({String label, int pos})>[];
    if (mode == 'hourly') {
      for (int i = 0; i < 24; i++) {
        tooltips.add('${i.toString().padLeft(2, '0')}:00 : ${distRaw[i]} Trx');
      }
      xLabels.addAll(const [
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
      xLabels.addAll(const [
        (label: '01', pos: 1),
        (label: '10', pos: 10),
        (label: '20', pos: 20),
        (label: '31', pos: 31),
      ]);
    } else {
      for (int i = 0; i < 12; i++) {
        tooltips.add('Bulan ${monthNames[i]} : ${distRaw[i]} Trx');
      }
      xLabels.addAll(const [
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
        'total': qris + tunai + transfer,
      },
      productSales: productSales,
      expenseCats: cats,
      distributionMode: mode,
      chartBars: bars,
      chartTooltips: tooltips,
      chartXLabels: xLabels,
      recent: filtered.take(5).toList(),
    );
  }

  @override
  Future<List<Transaction>> getDetailedHistory(HistoryQuery query) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final now = DateTime.now();

    bool includeByDate(Transaction t) {
      switch (query.mode) {
        case HistoryFilter.today:
          return isSameDay(t.createdAt, now);
        case HistoryFilter.month:
          return isSameMonth(t.createdAt, now);
        case HistoryFilter.all:
          return true;
        case HistoryFilter.custom:
          if (query.start == null || query.end == null) return false;
          final s =
              DateTime(query.start!.year, query.start!.month, query.start!.day);
          final e = DateTime(
              query.end!.year, query.end!.month, query.end!.day, 23, 59, 59);
          return !t.createdAt.isBefore(s) && !t.createdAt.isAfter(e);
      }
    }

    final list = _applyRoleFilter(
      _txs
          .where(includeByDate)
          .where((t) => query.type == null || t.type == query.type)
          .toList(),
    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ── Employee management (mock stubs) ─────────────────────────────────────

  final List<Employee> _employees = [
    Employee(
      id: '00000000-0000-0000-0000-000000000001',
      employeeId: 'ROASTER-01',
      name: 'Roaster',
      role: 'admin',
      active: true,
      createdAt: DateTime(2024, 1, 1),
    ),
    Employee(
      id: '00000000-0000-0000-0000-000000000002',
      employeeId: 'BARISTA-01',
      name: 'Barista',
      role: 'staff',
      active: true,
      createdAt: DateTime(2024, 1, 2),
    ),
  ];

  @override
  Future<List<Employee>> getEmployees() async => List.of(_employees);

  @override
  Future<({bool success, String message})> createEmployee({
    required String employeeId,
    required String name,
    required String role,
    required String pin,
  }) async {
    final id = employeeId.trim().toUpperCase();
    if (_employees.any((e) => e.employeeId == id)) {
      return (success: false, message: 'Employee ID sudah digunakan.');
    }
    _users[id] = pin;
    _employees.add(Employee(
      id: 'mock-${_employees.length + 1}',
      employeeId: id,
      name: name.trim(),
      role: role,
      active: true,
      createdAt: DateTime.now(),
    ));
    return (success: true, message: 'Karyawan berhasil ditambahkan.');
  }

  @override
  Future<({bool success, String message})> updateEmployee({
    required String employeeId,
    required String name,
    required String role,
    String? newPin,
  }) async {
    final idx = _employees.indexWhere((e) => e.employeeId == employeeId);
    if (idx == -1) {
      return (success: false, message: 'Karyawan tidak ditemukan.');
    }
    final old = _employees[idx];
    _employees[idx] = Employee(
      id: old.id,
      employeeId: old.employeeId,
      name: name.trim(),
      role: role,
      active: old.active,
      createdAt: old.createdAt,
    );
    if (newPin != null && newPin.length == 4) {
      _users[employeeId] = newPin;
    }
    return (success: true, message: 'Data karyawan berhasil diperbarui.');
  }

  @override
  Future<({bool success, String message})> toggleEmployeeActive(
      String employeeId) async {
    final idx = _employees.indexWhere((e) => e.employeeId == employeeId);
    if (idx == -1) {
      return (success: false, message: 'Karyawan tidak ditemukan.');
    }
    final old = _employees[idx];
    final nowActive = !old.active;
    _employees[idx] = Employee(
      id: old.id,
      employeeId: old.employeeId,
      name: old.name,
      role: old.role,
      active: nowActive,
      createdAt: old.createdAt,
    );
    return (
      success: true,
      message: 'Karyawan berhasil ${nowActive ? 'diaktifkan' : 'dinonaktifkan'}.',
    );
  }
}
