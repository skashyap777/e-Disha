import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Spacing constants
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;

  // Radius constants
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radiusFull = 999.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryStatic,
        brightness: Brightness.light,
      ),
      extensions: const [
        AppColors.light,
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryStatic,
        brightness: Brightness.dark,
      ),
      extensions: const [
        AppColors.dark,
      ],
    );
  }

  static List<BoxShadow> getShadow(ThemeData theme) {
    return [
      BoxShadow(
        color: theme.colorScheme.onSurface.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}