import 'package:flutter/material.dart';

class AppColors {
  static const allyPrimary = Color(0xFF4CAF50);
  static const allyLight = Color(0xFF81C784);
  static const allyDark = Color(0xFF388E3C);

  static const enemyPrimary = Color(0xFFE53935);
  static const enemyLight = Color(0xFFEF9A9A);
  static const enemyDark = Color(0xFFB71C1C);

  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceVariant = Color(0xFF2C2C2C);
  static const onSurface = Color(0xFFE0E0E0);
  static const onSurfaceMuted = Color(0xFF9E9E9E);

  static const hpBarHigh = Color(0xFF4CAF50);
  static const hpBarMid = Color(0xFFFFC107);
  static const hpBarLow = Color(0xFFE53935);

  static Color hpColor(int percent) {
    if (percent > 50) return hpBarHigh;
    if (percent > 25) return hpBarMid;
    return hpBarLow;
  }
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFCF6679),
      secondary: AppColors.allyPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surfaceVariant,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFCF6679),
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.onSurface,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(color: AppColors.onSurface, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
    ),
  );
}
