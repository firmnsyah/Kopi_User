enum TxType { income, expense }

class Transaction {
  final String id;
  final TxType type;
  final int amount;
  final String category;
  final String method;
  final String notes;
  final DateTime createdAt;
  final String? buktiPath;
  final String? employeeId;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.method,
    required this.notes,
    required this.createdAt,
    this.buktiPath,
    this.employeeId,
  });

  String get tipeLabel => type == TxType.income ? 'Pemasukan' : 'Pengeluaran';

  factory Transaction.fromJson(Map<String, dynamic> j) {
    return Transaction(
      id: (j['tx_id'] ?? j['txId'] ?? j['_id']) as String,
      type: j['type'] == 'income' ? TxType.income : TxType.expense,
      amount: (j['amount'] as num).toInt(),
      category: j['category'] as String,
      method: j['method'] as String,
      notes: (j['notes'] as String?) ?? '',
      createdAt: _parseUtc((j['created_at'] ?? j['createdAt']) as String).toLocal(),
      buktiPath: (j['bukti_url'] ?? j['buktiUrl']) as String?,
      employeeId: j['employee_id'] as String?,
    );
  }

  static DateTime _parseUtc(String dateStr) {
    if (!dateStr.endsWith('Z') && !dateStr.contains('+') && !dateStr.contains(RegExp(r'-[0-9]{2}:'))) {
      dateStr += 'Z';
    }
    return DateTime.parse(dateStr);
  }
}

class DashboardData {
  final int totalIncome;
  final int totalExpense;
  final Map<String, int> volume;
  final Map<String, int> expenseCats;
  final Map<String, int> productSales;
  final String distributionMode;
  final List<int> chartBars;
  final List<String> chartTooltips;
  final List<({String label, int pos})> chartXLabels;
  final List<Transaction> recent;

  DashboardData({
    required this.totalIncome,
    required this.totalExpense,
    required this.volume,
    required this.expenseCats,
    required this.productSales,
    required this.distributionMode,
    required this.chartBars,
    required this.chartTooltips,
    required this.chartXLabels,
    required this.recent,
  });

  int get profit => totalIncome - totalExpense;

  factory DashboardData.fromJson(Map<String, dynamic> j) {
    List<int> bars = (j['chartBars'] as List).map((e) => (e as num).toInt()).toList();
    List<String> tooltips = (j['chartTooltips'] as List).cast<String>();
    List<({String label, int pos})> xLabels = (j['chartXLabels'] as List)
        .map((e) => (label: e['label'] as String, pos: (e['pos'] as num).toInt()))
        .toList();
    List<Transaction> recent = (j['recent'] as List)
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
    Map<String, int> toIntMap(dynamic m) =>
        (m as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()));
    return DashboardData(
      totalIncome: (j['totalIncome'] as num).toInt(),
      totalExpense: (j['totalExpense'] as num).toInt(),
      volume: toIntMap(j['volume']),
      expenseCats: toIntMap(j['expenseCats']),
      productSales: toIntMap(j['productSales']),
      distributionMode: j['distributionMode'] as String,
      chartBars: bars,
      chartTooltips: tooltips,
      chartXLabels: xLabels,
      recent: recent,
    );
  }
}
