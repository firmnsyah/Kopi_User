import 'package:flutter/material.dart';

/// Palet warna adaptif: nilai berubah otomatis mengikuti [brightness].
///
/// Widget cukup memakai `AppColors.surface`, `AppColors.onSurface`, dst.
/// tanpa peduli tema aktif. Tema diatur lewat [ThemeController] yang
/// menyetel [brightness] sebelum pohon widget dibangun ulang.
class AppColors {
  AppColors._();

  /// Diset oleh ThemeController/main sebelum build. Default: terang.
  static Brightness brightness = Brightness.light;
  static bool get _dark => brightness == Brightness.dark;

  // ── Brand ─────────────────────────────────────────────────────────────────
  static Color get primary => _dark ? _dPrimary : _lPrimary;
  static Color get primaryContainer =>
      _dark ? _dPrimaryContainer : _lPrimaryContainer;
  static Color get secondary => _dark ? _dSecondary : _lSecondary;
  static Color get secondaryAccent =>
      _dark ? _dSecondaryAccent : _lSecondaryAccent;
  static Color get tertiary => _dark ? _dTertiary : _lTertiary;

  // ── Surface ───────────────────────────────────────────────────────────────
  static Color get surface => _dark ? _dSurface : _lSurface;
  static Color get surfaceContainerLow =>
      _dark ? _dSurfaceContainerLow : _lSurfaceContainerLow;
  static Color get surfaceContainer =>
      _dark ? _dSurfaceContainer : _lSurfaceContainer;
  static Color get surfaceContainerHighest =>
      _dark ? _dSurfaceContainerHighest : _lSurfaceContainerHighest;

  /// Latar kartu putih di mode terang, gelap di mode gelap.
  static Color get card => _dark ? _dCard : _lCard;

  static Color get outlineVariant => _dark ? _dOutlineVariant : _lOutlineVariant;
  static Color get secondaryFixedDim =>
      _dark ? _dSecondaryFixedDim : _lSecondaryFixedDim;

  static Color get onSurface => _dark ? _dOnSurface : _lOnSurface;
  static Color get onPrimary => Colors.white;

  // ── Status & chart ─────────────────────────────────────────────────────────
  static Color get success => _dark ? _dSuccess : _lSuccess;
  static Color get error => _dark ? _dError : _lError;

  static Color get incomeColor => _dark ? _dIncome : _lIncome;
  static Color get expenseColor => _dark ? _dExpense : _lExpense;
  static Color get profitColor => _dark ? _dProfit : _lProfit;
  static Color get lossColor => _dark ? _dLoss : _lLoss;
  static Color get chartBarColor => _dark ? _dChartBar : _lChartBar;
  static Color get chartBarActiveColor => primary;

  // ── Palet TERANG ───────────────────────────────────────────────────────────
  static const _lPrimary = Color(0xFF223628);
  static const _lPrimaryContainer = Color(0xFF384D3E);
  static const _lSecondary = Color(0xFF3D3733);
  static const _lSecondaryAccent = Color(0xFF77574D);
  static const _lTertiary = Color(0xFF492B08);

  static const _lSurface = Color(0xFFFFFFFF);
  static const _lSurfaceContainerLow = Color(0xFFFAF2EA);
  static const _lSurfaceContainer = Color(0xFFF4EDE5);
  static const _lSurfaceContainerHighest = Color(0xFFE8E1DA);
  static const _lCard = Color(0xFFFFFFFF);

  static const _lOutlineVariant = Color(0xFFC3C8C1);
  static const _lSecondaryFixedDim = Color(0xFFE7BDB1);

  static const _lOnSurface = Color(0xFF1E1B17);

  static const _lSuccess = Color(0xFF2E7D32);
  static const _lError = Color(0xFFC62828);

  static const _lIncome = Color(0xFF2D6A3E);
  static const _lExpense = Color(0xFFE8DFC3);
  static const _lProfit = Color(0xFF1A5276);
  static const _lLoss = Color(0xFFC62828);
  static const _lChartBar = Color(0xFFD4D0CC);

  // ── Palet GELAP ────────────────────────────────────────────────────────────
  static const _dPrimary = Color(0xFF3E8C5C);
  static const _dPrimaryContainer = Color(0xFF2A5C3D);
  static const _dSecondary = Color(0xFFB5ACA2);
  static const _dSecondaryAccent = Color(0xFFC99A8C);
  static const _dTertiary = Color(0xFFD7A15C);

  static const _dSurface = Color(0xFF141310);
  static const _dSurfaceContainerLow = Color(0xFF1C1A15);
  static const _dSurfaceContainer = Color(0xFF24211B);
  static const _dSurfaceContainerHighest = Color(0xFF302C24);
  static const _dCard = Color(0xFF1E1C16);

  static const _dOutlineVariant = Color(0xFF45413A);
  static const _dSecondaryFixedDim = Color(0xFF6B4A40);

  static const _dOnSurface = Color(0xFFECE6DE);

  static const _dSuccess = Color(0xFF66BB6A);
  static const _dError = Color(0xFFEF5350);

  static const _dIncome = Color(0xFF2D6A3E);
  static const _dExpense = Color(0xFFE8DFC3);
  static const _dProfit = Color(0xFF1A5276);
  static const _dLoss = Color(0xFFC62828);
  static const _dChartBar = Color(0xFF3A372F);
}
