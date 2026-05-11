class Employee {
  final String id;
  final String employeeId;
  final String name;
  final String role;
  final bool active;
  final DateTime createdAt;

  const Employee({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.role,
    required this.active,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id: j['id'] as String,
        employeeId: j['employee_id'] as String,
        name: j['name'] as String,
        role: j['role'] as String,
        active: j['active'] as bool? ?? true,
        createdAt: _parseUtc(j['created_at'] as String).toLocal(),
      );

  static DateTime _parseUtc(String dateStr) {
    if (!dateStr.endsWith('Z') && !dateStr.contains('+') && !dateStr.contains(RegExp(r'-[0-9]{2}:'))) {
      dateStr += 'Z';
    }
    return DateTime.parse(dateStr);
  }
}
