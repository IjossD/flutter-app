import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFF7F5F2);
  static const Color surface = Color(0xFFFFFCF8);
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color sage = Color(0xFF6EC6A0);
  static const Color amber = Color(0xFFF5C87A);
  static const Color terracotta = Color(0xFFE8916A);
  static const Color mutedTerracotta = Color(0xFFD4756A);

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: sage,
      secondary: amber,
      tertiary: terracotta,
      surface: surface,
      error: mutedTerracotta,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: sage.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textPrimary,
        ),
      ),
    );
  }
}
