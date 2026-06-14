import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String _headlineFamily = 'Epilogue';
  static const String _bodyFamily = 'WorkSans';
  static const double _sizeBoost = 2;

  static TextStyle headline({
    double size = 16,
    FontWeight weight = FontWeight.w800,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _headlineFamily,
      fontSize: size + _sizeBoost,
      fontWeight: weight,
      color: color ?? AppColors.onSurface,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _bodyFamily,
      fontSize: size + _sizeBoost,
      fontWeight: weight,
      color: color ?? AppColors.onSurface,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle label({
    double size = 10,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: _bodyFamily,
      fontSize: size + _sizeBoost,
      fontWeight: weight,
      color: color ?? AppColors.secondary,
      letterSpacing: 1.6,
    );
  }

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    // Warna tema dibaca dari palet sesuai brightness yang diminta — bukan dari
    // AppColors.brightness global, karena light() & dark() dibangun bersamaan.
    final surface = isDark ? const Color(0xFF141310) : const Color(0xFFFFFFFF);
    final onSurface = isDark ? const Color(0xFFECE6DE) : const Color(0xFF1E1B17);
    final primary = isDark ? const Color(0xFF3E8C5C) : const Color(0xFF223628);
    final secondary = isDark ? const Color(0xFFB5ACA2) : const Color(0xFF3D3733);
    final error = isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
    final outline = isDark ? const Color(0xFF45413A) : const Color(0xFFC3C8C1);
    final fill = isDark ? const Color(0xFF1E1C16) : Colors.white;

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        error: error,
        onError: Colors.white,
      ),
      textTheme: base.textTheme.apply(fontFamily: _bodyFamily).apply(
            bodyColor: onSurface,
            displayColor: onSurface,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _headlineFamily,
          fontSize: 18 + _sizeBoost,
          fontWeight: FontWeight.w800,
          color: primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
