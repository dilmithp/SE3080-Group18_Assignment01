import 'package:flutter/material.dart';

import 'package:elderly_companion/core/theme/app_colors.dart';
import 'package:elderly_companion/core/theme/app_typography.dart';

/// Builds the app's [ThemeData]. Every interactive control here enforces a
/// minimum 48x48 tap target (WCAG 2.5.5 / Material accessibility guidance)
/// because the primary users are elderly and often have reduced dexterity.
class AppTheme {
  const AppTheme._();

  static const double minTapTarget = 48;

  static ThemeData light({bool highContrast = false}) {
    final primary = highContrast ? AppColors.hcPrimary : AppColors.primary;
    final onPrimary = highContrast ? AppColors.hcOnPrimary : AppColors.onPrimary;
    final background = highContrast ? AppColors.hcBackground : AppColors.background;
    final onBackground = highContrast ? AppColors.hcOnBackground : AppColors.onBackground;
    final surface = highContrast ? AppColors.hcSurface : AppColors.surface;
    final onSurface = highContrast ? AppColors.hcOnSurface : AppColors.onSurface;
    final error = highContrast ? AppColors.hcError : AppColors.error;
    final border = highContrast ? AppColors.hcBorder : AppColors.border;
    final textTheme = highContrast ? AppTypography.highContrast : AppTypography.standard;

    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      secondary: highContrast ? AppColors.hcPrimary : AppColors.secondary,
      onSecondary: onPrimary,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: AppColors.onError,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: onPrimary),
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(double.infinity, minTapTarget),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, minTapTarget),
          side: BorderSide(color: border, width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, minTapTarget),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconTheme: IconThemeData(color: onBackground, size: 28),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: highContrast ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highContrast ? BorderSide(color: border) : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
    );
  }
}
