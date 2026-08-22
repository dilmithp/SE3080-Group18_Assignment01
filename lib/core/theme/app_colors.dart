import 'package:flutter/material.dart';

/// Colour palette for the app.
///
/// Every foreground/background pairing below was measured with the WCAG 2.1
/// relative-luminance formula, not eyeballed — the computed ratio is recorded
/// next to each token. Body text pairs clear AA (4.5:1); the `hc*` palette
/// clears AAA (7:1) because that is the entire point of high-contrast mode.
/// Non-text UI (borders, outlines) clears the 3:1 floor of WCAG 1.4.11.
///
/// Identity: a deep teal-blue reads as calm and trustworthy, while the warm
/// terracotta tertiary and warm-neutral background keep the product feeling
/// like companionship rather than clinical treatment.
class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------- standard

  /// Deep teal-blue. Bridges a trustworthy blue with the brand's original
  /// teal-green so the app never reads as a hospital tool.
  static const Color primary = Color(0xFF0E5A6B); // 7.80:1 on onPrimary (AAA)
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDCF2F6);
  static const Color onPrimaryContainer = Color(0xFF06333D); // 11.67:1

  /// Reassuring green for "verified / available" cues. Darkened from the
  /// reference #16A34A, which only reaches 3.30:1 against white and so could
  /// never carry white label text.
  static const Color secondary = Color(0xFF15803D); // 5.02:1 on onSecondary
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD7F2E0);
  static const Color onSecondaryContainer = Color(0xFF0B4A24); // 8.75:1

  /// Warm terracotta evolved from the original #8A5A2B brown. Used sparingly
  /// (badges, highlights, warm accents) — this is what keeps the palette warm.
  static const Color tertiary = Color(0xFF9A4A26); // 6.21:1 on onTertiary
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFCEBDA);
  static const Color onTertiaryContainer = Color(0xFF5A2A10); // 10.17:1

  /// Warm neutral, deliberately not blue-tinted.
  static const Color background = Color(0xFFFAF8F4);
  static const Color onBackground = Color(0xFF1C1917); // 16.49:1

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1C1917); // 16.61:1

  /// Warm tinted surfaces for grouped/secondary panels. Overridden over the
  /// seeded tonal palette so containers stay warm instead of teal-tinted.
  static const Color surfaceLow = Color(0xFFFAF8F4);
  static const Color surfaceContainer = Color(0xFFF5F1EB);
  static const Color surfaceContainerHigh = Color(0xFFF2EEE8);
  static const Color surfaceContainerHighest = Color(0xFFEDE8E0); // 14.34:1

  static const Color error = Color(0xFFB3261E); // 6.54:1 on onError
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFBE4E2);
  static const Color onErrorContainer = Color(0xFF5F1412); // 10.84:1

  static const Color success = secondary;
  static const Color textSecondary = Color(0xFF57534E); // 7.19:1 on background

  /// 3.74:1 on [surface] — clears WCAG 1.4.11 so input and card outlines stay
  /// visible to low-vision users (the old #BDBDBD managed only 1.88:1).
  static const Color border = Color(0xFF8A837C);

  /// Hairline used to define card edges against the warm background. Purely
  /// decorative — no information is carried by it alone.
  static const Color outlineVariant = Color(0xFFE3DDD4);
  static const Color disabled = Color(0xFF8E8880);

  /// Warm near-black used for the (subtle) elevation shadows.
  static const Color shadow = Color(0xFF1C1917);

  /// Dark neutral for snackbars / inverse surfaces.
  static const Color inverseSurface = Color(0xFF2B2724);
  static const Color onInverseSurface = Color(0xFFFFFFFF); // 14.81:1

  // ---------------------------------------------------- high contrast (AAA)
  // Toggled by AccessibilityController.highContrast.

  static const Color hcPrimary = Color(0xFF00343F); // 13.44:1 on hcOnPrimary
  static const Color hcOnPrimary = Color(0xFFFFFFFF);
  static const Color hcPrimaryContainer = Color(0xFFE8F4F7);
  static const Color hcOnPrimaryContainer = Color(0xFF00232B); // 14.67:1

  static const Color hcSecondary = Color(0xFF0A4A23); // 10.41:1
  static const Color hcOnSecondary = Color(0xFFFFFFFF);
  static const Color hcSecondaryContainer = Color(0xFFE3F5EA);
  static const Color hcOnSecondaryContainer = Color(0xFF052F14); // 13.01:1

  static const Color hcTertiary = Color(0xFF5C2C12); // 11.51:1
  static const Color hcOnTertiary = Color(0xFFFFFFFF);
  static const Color hcTertiaryContainer = Color(0xFFFBEEE2);
  static const Color hcOnTertiaryContainer = Color(0xFF3F1C08); // 13.35:1

  static const Color hcBackground = Color(0xFFFFFFFF);
  static const Color hcOnBackground = Color(0xFF000000); // 21:1
  static const Color hcSurface = Color(0xFFFFFFFF);
  static const Color hcOnSurface = Color(0xFF000000); // 21:1
  static const Color hcSurfaceContainer = Color(0xFFF2F2F2);

  static const Color hcError = Color(0xFF7A0000); // 11.49:1
  static const Color hcOnError = Color(0xFFFFFFFF);
  static const Color hcErrorContainer = Color(0xFFFDECEA);
  static const Color hcOnErrorContainer = Color(0xFF4A0000); // 14.22:1

  static const Color hcTextSecondary = Color(0xFF262626); // 15.13:1
  static const Color hcBorder = Color(0xFF000000);

  /// High contrast draws every edge as a solid black line rather than relying
  /// on shadow or a hairline tint, so the variant collapses to [hcBorder].
  static const Color hcOutlineVariant = Color(0xFF000000);
  static const Color hcDisabled = Color(0xFF595959);
}
