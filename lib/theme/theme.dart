import 'package:flutter/material.dart';
import 'package:edisha/theme/app_colors.dart';

class AppTheme {
  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;

  // Border Radius
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius32 = 32.0;
  static const double radiusFull = 999.0;

  // Shadows
  static List<BoxShadow> getShadow(Color color) => [
        BoxShadow(
          color: color,
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  static final ThemeData lightTheme = _buildTheme(brightness: Brightness.light);
  static final ThemeData darkTheme = _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    // Define base color schemes
    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: Color(0xFF3F51B5),
            secondary: Color(0xFF9C27B0),
            surface: Color(0xFF303030),
            error: Color(0xFFEF5350),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Color(0xFFFFFFFF),
            onError: Colors.black,
          )
        : const ColorScheme.light(
            primary: Color(0xFF2563EB),
            secondary: Color(0xFF7C3AED),
            surface: Colors.white,
            error: Color(0xFFEF4444),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Color(0xFF111827),
            onError: Colors.white,
          );

    // Define custom colors via the theme extension
    final appColors = AppColors(
      success: isDark ? const Color(0xFF66BB6A) : const Color(0xFF10B981),
      successLight: isDark ? const Color(0xFF81C784) : const Color(0xFF34D399),
      warning: isDark ? const Color(0xFFFFCA28) : const Color(0xFFF59E0B),
      info: isDark ? const Color(0xFF29B6F6) : const Color(0xFF06B6D4),
      infoLight: isDark ? const Color(0xFF4FC3F7) : const Color(0xFF22D3EE),
      neutral: isDark
          ? {
              50: const Color(0xFF212121),
              100: const Color(0xFF303030),
              200: const Color(0xFF424242),
              300: const Color(0xFF616161),
              400: const Color(0xFF757575),
              500: const Color(0xFF9E9E9E),
              600: const Color(0xFFBDBDBD),
              700: const Color(0xFFE0E0E0),
              800: const Color(0xFFEEEEEE),
              900: const Color(0xFFFFFFFF),
            }
          : {
              50: const Color(0xFFF9FAFB),
              100: const Color(0xFFF3F4F6),
              200: const Color(0xFFE5E7EB),
              300: const Color(0xFFD1D5DB),
              400: const Color(0xFF9CA3AF),
              500: const Color(0xFF6B7280),
              600: const Color(0xFF4B5563),
              700: const Color(0xFF374151),
              800: const Color(0xFF1F2937),
              900: const Color(0xFF111827),
            },
      border: {
        'default': isDark ? const Color(0xFF424242) : const Color(0xFFE5E7EB),
      },
      shadow: {
        'default': isDark
            ? Colors.transparent
            : const Color(0xFF111827).withOpacity(0.1),
      },
      primaryGradient: LinearGradient(
        colors: [colorScheme.primary, colorScheme.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      successGradient: LinearGradient(
        colors: [
          isDark ? const Color(0xFF66BB6A) : const Color(0xFF10B981),
          isDark ? const Color(0xFF81C784) : const Color(0xFF34D399),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      errorGradient: LinearGradient(
        colors: [
          colorScheme.error,
          isDark ? const Color(0xFFE57373) : const Color(0xFFF87171),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      infoGradient: LinearGradient(
        colors: [
          isDark ? const Color(0xFF29B6F6) : const Color(0xFF06B6D4),
          isDark ? const Color(0xFF4FC3F7) : const Color(0xFF22D3EE),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );

    final baseTheme = ThemeData(brightness: brightness);

    // Define Text Theme
    final textTheme = baseTheme.textTheme
        .copyWith(
          headlineLarge: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              height: 1.2),
          headlineMedium: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.25,
              height: 1.3),
          headlineSmall: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              height: 1.4),
          titleLarge: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              height: 1.5),
          bodyLarge: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.5,
              height: 1.6),
          bodyMedium: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.25,
              height: 1.6),
          bodySmall: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.4,
              height: 1.4),
          labelLarge: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.75,
              height: 1.2),
        )
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    // Define Component Themes
    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius12));
    const buttonPadding =
        EdgeInsets.symmetric(horizontal: spacing24, vertical: spacing16);
    final buttonTextStyle = textTheme.labelLarge;

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: colorScheme.surface,
      extensions: <ThemeExtension<dynamic>>[appColors],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: BorderSide(color: appColors.border['default']!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: BorderSide(color: appColors.border['default']!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: spacing16, vertical: spacing16),
        hintStyle: textTheme.bodyLarge!.copyWith(color: appColors.neutral[500]),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: buttonTextStyle,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius8)),
          padding: const EdgeInsets.symmetric(
              horizontal: spacing16, vertical: spacing8),
          textStyle: buttonTextStyle,
        ),
      ),
    );
  }
}
