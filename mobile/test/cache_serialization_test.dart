import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kopi_user/models/transaction.dart';

void main() {
  test('Transaction round-trips through JSON cache', () {
    final tx = Transaction(
      id: 'TX001',
      type: TxType.income,
      amount: 25000,
      category: '2x Kopi Susu, 1x Americano',
      method: 'QRIS',
      notes: 'Catatan uji',
      createdAt: DateTime(2026, 6, 14, 9, 30),
      buktiPath: 'https://example.com/bukti.png',
      employeeId: 'EMP1',
    );

    final restored =
        Transaction.fromJson(jsonDecode(jsonEncode(tx.toJson())));

    expect(restored.id, tx.id);
    expect(restored.type, tx.type);
    expect(restored.amount, tx.amount);
    expect(restored.category, tx.category);
    expect(restored.method, tx.method);
    expect(restored.notes, tx.notes);
    expect(restored.buktiPath, tx.buktiPath);
    expect(restored.employeeId, tx.employeeId);
    // Waktu harus identik meski lewat konversi UTC.
    expect(restored.createdAt.toUtc(), tx.createdAt.toUtc());
  });

  test('DashboardData round-trips through JSON cache', () {
    final data = DashboardData(
      totalIncome: 150000,
      totalExpense: 80000,
      volume: {'qris': 3, 'tunai': 2, 'transfer': 1, 'total': 6},
      expenseCats: {'Bahan Baku': 50000, 'Operasional': 30000},
      productSales: {'Kopi Susu': 12, 'Americano': 5},
      distributionMode: 'hourly',
      chartBars: [0, 50, 100, 25],
      chartTooltips: const ['00:00 : 0 Trx', '01:00 : 3 Trx'],
      chartXLabels: const [(label: '00', pos: 1), (label: '04', pos: 5)],
      recent: [
        Transaction(
          id: 'TX9',
          type: TxType.expense,
          amount: 10000,
          category: 'Operasional',
          method: 'TUNAI',
          notes: '',
          createdAt: DateTime(2026, 6, 14, 8),
        ),
      ],
    );

    final restored =
        DashboardData.fromJson(jsonDecode(jsonEncode(data.toJson())));

    expect(restored.totalIncome, data.totalIncome);
    expect(restored.totalExpense, data.totalExpense);
    expect(restored.profit, data.profit);
    expect(restored.volume, data.volume);
    expect(restored.expenseCats, data.expenseCats);
    expect(restored.productSales, data.productSales);
    expect(restored.distributionMode, data.distributionMode);
    expect(restored.chartBars, data.chartBars);
    expect(restored.chartTooltips, data.chartTooltips);
    expect(restored.chartXLabels, data.chartXLabels);
    expect(restored.recent.length, 1);
    expect(restored.recent.first.id, 'TX9');
  });
}
