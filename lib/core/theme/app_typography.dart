import 'package:flutter/material.dart';

import 'package:elderly_companion/core/theme/app_colors.dart';

/// Text styles for the app. Body text is 16sp minimum — the user base
/// skews elderly, so we never rely on Flutter's smaller Material defaults
/// (bodySmall etc. are still legible, but nothing goes below 14sp and the
/// primary reading sizes start at 16sp).
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Color onBackground) => TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: onBackground,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: onBackground,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onBackground,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onBackground,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: onBackground,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: onBackground,
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: onBackground,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onBackground,
        ),
      );

  static final TextTheme standard = textTheme(AppColors.onBackground);
  static final TextTheme highContrast = textTheme(AppColors.hcOnBackground);
}
