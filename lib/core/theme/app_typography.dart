import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:elderly_companion/core/theme/app_colors.dart';

/// Text styles for the app, built from two legibility-first typefaces:
///
/// * **Atkinson Hyperlegible** — every body role. Commissioned by the Braille
///   Institute specifically to disambiguate letterforms (I/l/1, O/0, b/d) for
///   low-vision readers, which is exactly this app's audience.
/// * **Lexend** — display, headline, title and label roles. A modern geometric
///   sans with a full weight range, so hierarchy comes from weight rather than
///   from shrinking anything.
///
/// Sizes are unchanged from the original scale: nothing drops below 14sp and
/// the primary reading sizes start at 16sp. Only weight, letter-spacing and
/// line-height were tuned. Generous line-height (1.5–1.6 on body) matters more
/// than font size for older readers tracking from one line to the next.
class AppTypography {
  const AppTypography._();

  /// Atkinson ships only w400 and w700, so body roles never ask for a weight
  /// outside that range — an unavailable weight would be synthesised and lose
  /// the letterform tuning that makes the face worth using.
  static TextStyle _body(
    Color color, {
    required double size,
    required double letterSpacing,
    required double height,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.atkinsonHyperlegible(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  static TextStyle _heading(
    Color color, {
    required double size,
    required FontWeight weight,
    required double letterSpacing,
    required double height,
  }) {
    return GoogleFonts.lexend(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  static TextTheme textTheme(Color onBackground) => TextTheme(
        displayLarge: _heading(
          onBackground,
          size: 34,
          weight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.15,
        ),
        headlineLarge: _heading(
          onBackground,
          size: 28,
          weight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.2,
        ),
        headlineMedium: _heading(
          onBackground,
          size: 24,
          weight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1.25,
        ),
        titleLarge: _heading(
          onBackground,
          size: 20,
          weight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.3,
        ),
        bodyLarge: _body(
          onBackground,
          size: 18,
          letterSpacing: 0.1,
          height: 1.55,
        ),
        bodyMedium: _body(
          onBackground,
          size: 16,
          letterSpacing: 0.1,
          height: 1.55,
        ),
        bodySmall: _body(
          onBackground,
          size: 14,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        labelLarge: _heading(
          onBackground,
          size: 16,
          weight: FontWeight.w600,
          letterSpacing: 0.2,
          height: 1.2,
        ),
      );

  static final TextTheme standard = textTheme(AppColors.onBackground);
  static final TextTheme highContrast = textTheme(AppColors.hcOnBackground);
}
