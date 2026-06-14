import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

/// Menyimpan pilihan tema (terang/gelap) dan mempertahankannya antar sesi
/// lewat SharedPreferences. Menyetel [AppColors.brightness] agar palet
/// adaptif ikut berubah setiap kali tema diganti.
class ThemeController extends ChangeNotifier {
  static const _kThemeMode = 'kopiuser_theme_mode';

  ThemeMode _mode;

  ThemeController([ThemeMode initial = ThemeMode.light]) : _mode = initial {
    _sync();
  }

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  /// Brightness efektif dari pilihan tema (hanya terang/gelap eksplisit).
  Brightness get brightness =>
      _mode == ThemeMode.dark ? Brightness.dark : Brightness.light;

  /// Memuat pilihan tersimpan. Panggil sekali sebelum runApp.
  static Future<ThemeController> load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_kThemeMode);
    final mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    return ThemeController(mode);
  }

  Future<void> toggle() => setDark(!isDark);

  Future<void> setDark(bool dark) async {
    final next = dark ? ThemeMode.dark : ThemeMode.light;
    if (next == _mode) return;
    _mode = next;
    _sync();
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kThemeMode, dark ? 'dark' : 'light');
  }

  void _sync() => AppColors.brightness = brightness;
}
