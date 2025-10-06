import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.success,
    required this.warning,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.divider,
    required this.cardBackground,
    required this.disabled,
    required this.primaryGradient,
    required this.shadow,
    required this.neutral,
  });

  final Color primary;
  final Color secondary;
  final Color surface;
  final Color background;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color onBackground;
  final Color error;
  final Color onError;
  final Color success;
  final Color warning;
  final Color info;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color divider;
  final Color cardBackground;
  final Color disabled;
  final List<Color> primaryGradient;
  final List<BoxShadow> shadow;
  final Map<int, Color> neutral;

  // e-Disha Professional Brand Colors
  static const Color primaryValue = Color(0xFF1E3A8A); // Professional blue
  static const Color secondaryValue = Color(0xFF06B6D4); // Cyan accent
  static const Color errorValue = Color(0xFFDC2626); // Professional red
  static const Color successValue = Color(0xFF10B981); // Success green
  static const Color warningValue = Color(0xFFF59E0B); // Warning amber
  static const Color infoValue = Color(0xFF3B82F6); // Info blue

  // Static primary color for access without theme context
  static const Color primaryStatic = primaryValue;
  
  // Additional e-Disha colors
  static const Color accentTeal = Color(0xFF06B6D4);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color lightBackground = Color(0xFFFAFAFA);
  
  // Modern gradients
  static const List<Color> eDishaPrimaryGradient = [
    Color(0xFF1E3A8A),
    Color(0xFF3B82F6),
    Color(0xFF60A5FA),
  ];
  
  static const List<Color> eDishaCyanGradient = [
    Color(0xFF06B6D4),
    Color(0xFF22D3EE),
  ];
  
  static const List<Color> eDishaSuccessGradient = [
    Color(0xFF10B981),
    Color(0xFF34D399),
  ];
  
  // Glassmorphism support
  static const List<Color> glassGradient = [
    Color(0x20FFFFFF),
    Color(0x10FFFFFF),
  ];
  
  // Helper method to get app colors from context
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }

  static const AppColors light = AppColors(
    primary: primaryValue,
    secondary: secondaryValue,
    surface: Color(0xFFFFFFFF),
    background: lightBackground,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.black87,
    onBackground: Colors.black87,
    error: errorValue,
    onError: Colors.white,
    success: successValue,
    warning: warningValue,
    info: infoValue,
    textPrimary: Colors.black87,
    textSecondary: Colors.black54,
    border: Color(0xFFE0E0E0),
    divider: Color(0xFFE0E0E0),
    cardBackground: Colors.white,
    disabled: Color(0xFFBDBDBD),
    primaryGradient: eDishaPrimaryGradient,
    shadow: [
      BoxShadow(
        color: Color(0x1F000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    neutral: {
      50: Color(0xFFFAFAFA),
      100: Color(0xFFF5F5F5),
      200: Color(0xFFEEEEEE),
      300: Color(0xFFE0E0E0),
      400: Color(0xFFBDBDBD),
      500: Color(0xFF9E9E9E),
      600: Color(0xFF757575),
      700: Color(0xFF616161),
      800: Color(0xFF424242),
      900: Color(0xFF212121),
    },
  );

  static const AppColors dark = AppColors(
    primary: primaryValue,
    secondary: secondaryValue,
    surface: Color(0xFF121212),
    background: Color(0xFF000000),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
    error: errorValue,
    onError: Colors.white,
    success: successValue,
    warning: warningValue,
    info: infoValue,
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    border: Color(0xFF424242),
    divider: Color(0xFF424242),
    cardBackground: Color(0xFF1E1E1E),
    disabled: Color(0xFF757575),
    primaryGradient: eDishaPrimaryGradient,
    shadow: [
      BoxShadow(
        color: Color(0x3F000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    neutral: {
      50: Color(0xFF212121),
      100: Color(0xFF424242),
      200: Color(0xFF616161),
      300: Color(0xFF757575),
      400: Color(0xFF9E9E9E),
      500: Color(0xFFBDBDBD),
      600: Color(0xFFE0E0E0),
      700: Color(0xFFEEEEEE),
      800: Color(0xFFF5F5F5),
      900: Color(0xFFFAFAFA),
    },
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? secondary,
    Color? surface,
    Color? background,
    Color? onPrimary,
    Color? onSecondary,
    Color? onSurface,
    Color? onBackground,
    Color? error,
    Color? onError,
    Color? success,
    Color? warning,
    Color? info,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? divider,
    Color? cardBackground,
    Color? disabled,
    List<Color>? primaryGradient,
    List<BoxShadow>? shadow,
    Map<int, Color>? neutral,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onSurface: onSurface ?? this.onSurface,
      onBackground: onBackground ?? this.onBackground,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      cardBackground: cardBackground ?? this.cardBackground,
      disabled: disabled ?? this.disabled,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      shadow: shadow ?? this.shadow,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      primaryGradient: t < 0.5 ? primaryGradient : other.primaryGradient,
      shadow: t < 0.5 ? shadow : other.shadow,
      neutral: t < 0.5 ? neutral : other.neutral,
    );
  }
}