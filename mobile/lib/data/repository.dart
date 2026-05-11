import '../models/employee.dart';
import '../models/transaction.dart';

enum HistoryFilter { today, month, all, custom }
enum DashboardFilter { today, month, all }

class HistoryQuery {
  final HistoryFilter mode;
  final DateTime? start;
  final DateTime? end;
  final TxType? type;

  const HistoryQuery({
    required this.mode,
    this.start,
    this.end,
    this.type,
  });
}

abstract class Repository {
  Future<({bool success, String? employeeId, String? role, String? token, String message})> clockIn(
    String employeeId,
    String pin,
  );

  Future<({bool success, String message, Transaction? tx})> saveTransaction({
    required TxType type,
    required int amount,
    required String category,
    required String method,
    required String notes,
    String? buktiPath,
  });

  Future<({bool success, String message, Transaction? tx})> updateTransaction({
    required String id,
    required TxType type,
    required int amount,
    required String category,
    required String method,
    required String notes,
    String? buktiPath,
    bool clearBukti = false,
  });

  Future<({bool success, String message})> deleteTransaction(String id);

  Future<DashboardData> getDashboard(DashboardFilter filter);

  Future<List<Transaction>> getDetailedHistory(HistoryQuery query);

  Future<List<Employee>> getEmployees();

  Future<({bool success, String message})> createEmployee({
    required String employeeId,
    required String name,
    required String role,
    required String pin,
  });

  Future<({bool success, String message})> updateEmployee({
    required String employeeId,
    required String name,
    required String role,
    String? newPin,
  });

  Future<({bool success, String message})> toggleEmployeeActive(String employeeId);
}
