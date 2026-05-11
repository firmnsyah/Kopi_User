import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSession extends ChangeNotifier {
  static const _kEmployee = 'kopiuser_employee';
  static const _kExpiresAt = 'kopiuser_expires_at';
  static const Duration _mockDuration = Duration(minutes: 120);

  final bool _supabaseMode;
  StreamSubscription<AuthState>? _sub;

  // mock-mode state
  String? _mockEmployeeId;
  String? _mockRole;
  DateTime? _mockExpiresAt;

  AppSession({bool supabaseMode = false}) : _supabaseMode = supabaseMode {
    if (supabaseMode) {
      _sub = Supabase.instance.client.auth.onAuthStateChange
          .listen((_) => notifyListeners());
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool get isLoggedIn {
    if (_supabaseMode) {
      return Supabase.instance.client.auth.currentSession != null;
    }
    return _mockEmployeeId != null &&
        _mockExpiresAt != null &&
        DateTime.now().isBefore(_mockExpiresAt!);
  }

  String? get employeeId {
    if (_supabaseMode) {
      final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
      return meta?['employee_id'] as String?;
    }
    return _mockEmployeeId;
  }

  String? get role {
    if (_supabaseMode) {
      final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
      return meta?['role'] as String?;
    }
    return _mockRole;
  }

  bool get isAdmin => role == 'admin';

  Future<void> load() async {
    if (_supabaseMode) return; // Supabase handles persistence automatically
    final p = await SharedPreferences.getInstance();
    _mockEmployeeId = p.getString(_kEmployee);
    final ms = p.getInt(_kExpiresAt);
    _mockExpiresAt =
        ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    if (!isLoggedIn) {
      _mockEmployeeId = null;
      _mockExpiresAt = null;
    }
    notifyListeners();
  }

  Future<void> signIn(String employeeId, {String? role, String? token}) async {
    if (_supabaseMode) {
      // Auth already completed in SupabaseRepository.clockIn;
      // auth state listener will call notifyListeners().
      return;
    }
    _mockEmployeeId = employeeId;
    _mockRole = role ?? 'staff';
    _mockExpiresAt = DateTime.now().add(_mockDuration);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kEmployee, employeeId);
    await p.setInt(_kExpiresAt, _mockExpiresAt!.millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_supabaseMode) {
      await Supabase.instance.client.auth.signOut();
      return;
    }
    _mockEmployeeId = null;
    _mockExpiresAt = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kEmployee);
    await p.remove(_kExpiresAt);
    notifyListeners();
  }
}
