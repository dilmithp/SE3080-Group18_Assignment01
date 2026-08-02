import 'package:flutter/material.dart';

/// Colour palette for the app. Every foreground/background pairing listed
/// here meets WCAG AA (4.5:1) contrast at minimum — verify with a contrast
/// checker before changing any value.
class AppColors {
  const AppColors._();

  // Standard palette
  static const Color primary = Color(0xFF2E5B4F); // deep teal-green
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF8A5A2B); // warm brown accent
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFFAF9F6);
  static const Color onBackground = Color(0xFF1B1B1B); // ~15.5:1 on background

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1B1B1B);

  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF1E6B3C);
  static const Color textSecondary = Color(0xFF444444); // ~9.7:1 on background

  static const Color border = Color(0xFFBDBDBD);
  static const Color disabled = Color(0xFF9E9E9E);

  // High-contrast palette — toggled by AccessibilityController.highContrast
  static const Color hcPrimary = Color(0xFF00382C);
  static const Color hcOnPrimary = Color(0xFFFFFFFF);
  static const Color hcBackground = Color(0xFFFFFFFF);
  static const Color hcOnBackground = Color(0xFF000000);
  static const Color hcSurface = Color(0xFFFFFFFF);
  static const Color hcOnSurface = Color(0xFF000000);
  static const Color hcError = Color(0xFF7A0000);
  static const Color hcBorder = Color(0xFF000000);
}
