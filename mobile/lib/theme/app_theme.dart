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
    Color color = AppColors.onSurface,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _headlineFamily,
      fontSize: size + _sizeBoost,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.onSurface,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _bodyFamily,
      fontSize: size + _sizeBoost,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle label({
    double size = 10,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.secondary,
  }) {
    return TextStyle(
      fontFamily: _bodyFamily,
      fontSize: size + _sizeBoost,
      fontWeight: weight,
      color: color,
      letterSpacing: 1.6,
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
      textTheme: base.textTheme
          .apply(fontFamily: _bodyFamily)
          .apply(
            bodyColor: AppColors.onSurface,
            displayColor: AppColors.onSurface,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: headline(size: 18, color: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
