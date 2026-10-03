import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFC3F400);
  static const onPrimary = Color(0xFF283500);
  static const secondary = Color(0xFF7BD0FF);
  static const tertiary = Color(0xFFC4C9AC);
  static const canvas = Color(0xFF111316);
  static const surface1 = Color(0xFF1E2023);
  static const surface2 = Color(0xFF282A2D);
  static const surface3 = Color(0xFF333538);
  static const text = Color(0xFFE2E2E6);
  static const textMuted = Color(0xFFC4C9AC);
  static const error = Color(0xFFFFB4AB);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const screen = 20.0;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    surface: AppColors.surface1,
    onSurface: AppColors.text,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    error: AppColors.error,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Plus Jakarta Sans',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.text,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface1,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.surface3),
  );
}
