import 'package:flutter/material.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color success;
  final Color warning;
  final Color greenPresent;
  final Color redAbsent;
  final Color amberExcused;
  final Color googleRed;

  const AppThemeExtension({
    required this.success,
    required this.warning,
    required this.greenPresent,
    required this.redAbsent,
    required this.amberExcused,
    required this.googleRed,
  });

  static const dark = AppThemeExtension(
    success: AppColors.success,
    warning: AppColors.warning,
    greenPresent: AppColors.greenPresent,
    redAbsent: AppColors.redAbsent,
    amberExcused: AppColors.amberExcused,
    googleRed: AppColors.googleRed,
  );

  static const light = AppThemeExtension(
    success: AppColors.success,
    warning: AppColors.warning,
    greenPresent: AppColors.greenPresent,
    redAbsent: AppColors.redAbsent,
    amberExcused: AppColors.amberExcused,
    googleRed: AppColors.googleRed,
  );

  @override
  AppThemeExtension copyWith({
    Color? success,
    Color? warning,
    Color? greenPresent,
    Color? redAbsent,
    Color? amberExcused,
    Color? googleRed,
  }) {
    return AppThemeExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      greenPresent: greenPresent ?? this.greenPresent,
      redAbsent: redAbsent ?? this.redAbsent,
      amberExcused: amberExcused ?? this.amberExcused,
      googleRed: googleRed ?? this.googleRed,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      greenPresent:
          Color.lerp(greenPresent, other.greenPresent, t) ?? greenPresent,
      redAbsent: Color.lerp(redAbsent, other.redAbsent, t) ?? redAbsent,
      amberExcused:
          Color.lerp(amberExcused, other.amberExcused, t) ?? amberExcused,
      googleRed: Color.lerp(googleRed, other.googleRed, t) ?? googleRed,
    );
  }
}
