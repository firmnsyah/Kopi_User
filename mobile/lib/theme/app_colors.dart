import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF223628);
  static const primaryContainer = Color(0xFF384D3E);
  static const secondary = Color(0xFF3D3733);
  static const secondaryAccent = Color(0xFF77574D);
  static const tertiary = Color(0xFF492B08);

  static const surface = Color(0xFFFFF8F1);
  static const surfaceContainerLow = Color(0xFFFAF2EA);
  static const surfaceContainer = Color(0xFFF4EDE5);
  static const surfaceContainerHighest = Color(0xFFE8E1DA);

  static const outlineVariant = Color(0xFFC3C8C1);
  static const secondaryFixedDim = Color(0xFFE7BDB1);

  static const onSurface = Color(0xFF1E1B17);
  static const onPrimary = Color(0xFFFFFFFF);

  static const success = Color(0xFF2E7D32);
  static const error = Color(0xFFC62828);

  static const incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D6A3E), Color(0xFF3A8F52), Color(0xFF7BC67E)],
    stops: [0.0, 0.5, 1.0],
  );

  static const expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4C9A8), Color(0xFFE8DFC3), Color(0xFFF0E8D0)],
    stops: [0.0, 0.5, 1.0],
  );

  static const profitGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A5276), Color(0xFF2980B9), Color(0xFF5DADE2)],
    stops: [0.0, 0.5, 1.0],
  );

  static const lossGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B2C2C), Color(0xFFC62828), Color(0xFFE57373)],
    stops: [0.0, 0.5, 1.0],
  );

  static const primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF223628), Color(0xFF384D3E)],
  );

  static const chartBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFC3C8C1), Color(0xFFE0DDD8)],
  );

  static const chartBarActiveGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF223628), Color(0xFF3A8F52)],
  );
}
