import 'package:flutter/material.dart';

/// Shared palette. Category colors live on [Category]; these are the
/// app-wide brand colors.
class AppColors {
  const AppColors._();

  static const ink = Color(0xFF1E1B3A);
  static const inkSoft = Color(0xFF6B6785);
  static const cream = Color(0xFFFFF8F0);
  static const purple = Color(0xFF6C4DFF);
  static const purpleLight = Color(0xFF9B6BFF);
  static const orange = Color(0xFFFF8A1F);
  static const pink = Color(0xFFFF4D8D);
  static const star = Color(0xFFFFD43B);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.purple,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
