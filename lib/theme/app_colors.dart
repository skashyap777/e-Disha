import 'package:flutter/material.dart';

/// A custom theme extension for additional app-specific colors and styles.
/// This allows for type-safe access to custom theme properties.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.successLight,
    required this.warning,
    required this.info,
    required this.infoLight,
    required this.neutral,
    required this.border,
    required this.shadow,
    required this.primaryGradient,
    required this.successGradient,
    required this.errorGradient,
    required this.infoGradient,
  });

  final Color success;
  final Color successLight;
  final Color warning;
  final Color info;
  final Color infoLight;
  final Map<int, Color> neutral;
  final Map<String, Color> border;
  final Map<String, Color> shadow;
  final LinearGradient primaryGradient;
  final LinearGradient successGradient;
  final LinearGradient errorGradient;
  final LinearGradient infoGradient;

  @override
  ThemeExtension<AppColors> copyWith({
    Color? success,
    Color? successLight,
    Color? warning,
    Color? info,
    Color? infoLight,
    Map<int, Color>? neutral,
    Map<String, Color>? border,
    Map<String, Color>? shadow,
    LinearGradient? primaryGradient,
    LinearGradient? successGradient,
    LinearGradient? errorGradient,
    LinearGradient? infoGradient,
  }) {
    return AppColors(
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      neutral: neutral ?? this.neutral,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      successGradient: successGradient ?? this.successGradient,
      errorGradient: errorGradient ?? this.errorGradient,
      infoGradient: infoGradient ?? this.infoGradient,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(
    covariant ThemeExtension<AppColors>? other,
    double t,
  ) {
    if (other is! AppColors) {
      return this;
    }
    // Helper to lerp maps of colors
    Map<K, Color> lerpColorMap<K>(
        Map<K, Color> from, Map<K, Color> to, double t) {
      final Map<K, Color> result = {};
      for (final key in from.keys) {
        if (to.containsKey(key)) {
          result[key] = Color.lerp(from[key], to[key], t)!;
        }
      }
      return result;
    }

    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      neutral: lerpColorMap(neutral, other.neutral, t),
      border: lerpColorMap(border, other.border, t),
      shadow: lerpColorMap(shadow, other.shadow, t),
      primaryGradient:
          LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      successGradient:
          LinearGradient.lerp(successGradient, other.successGradient, t)!,
      errorGradient:
          LinearGradient.lerp(errorGradient, other.errorGradient, t)!,
      infoGradient: LinearGradient.lerp(infoGradient, other.infoGradient, t)!,
    );
  }
}
