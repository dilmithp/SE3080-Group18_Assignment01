import 'package:flutter/material.dart';

import 'package:elderly_companion/core/theme/app_colors.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/theme/app_typography.dart';

/// Builds the app's [ThemeData].
///
/// Two rules govern everything below:
///
/// 1. **48x48 minimum tap target** on every interactive control (WCAG 2.5.5),
///    because the primary users are elderly and often have reduced dexterity.
/// 2. **Shape, elevation and spacing come from tokens** ([AppRadius],
///    [AppElevation], [AppSpacing]) rather than literals, so the visual
///    language stays consistent as screens are built out.
///
/// The colour scheme is seeded with `ColorScheme.fromSeed` to get a complete,
/// harmonious Material 3 tonal palette, then the load-bearing roles are
/// overridden with the hand-verified values in [AppColors] so contrast is
/// guaranteed rather than inferred.
class AppTheme {
  const AppTheme._();

  static const double minTapTarget = 48;

  /// Tap target and breathing room used instead of [minTapTarget] /
  /// [AppSpacing] when [AccessibilityState.simplifiedMode] is on — bigger
  /// targets and fewer visible secondary actions are what that flag exists
  /// for (see accessibility_state.dart).
  static const double minTapTargetSimplified = 64;

  /// All four variants are built once and cached. [light] is called from
  /// `App.build`, and `ColorScheme.fromSeed` runs a full tonal-palette
  /// quantisation there is no reason to repeat on every rebuild.
  static final ThemeData _standard = _build(_Palette.standard, simplified: false);
  static final ThemeData _contrast = _build(_Palette.contrast, simplified: false);
  static final ThemeData _standardSimplified =
      _build(_Palette.standard, simplified: true);
  static final ThemeData _contrastSimplified =
      _build(_Palette.contrast, simplified: true);

  static ThemeData light({bool highContrast = false, bool simplifiedMode = false}) {
    if (simplifiedMode) return highContrast ? _contrastSimplified : _standardSimplified;
    return highContrast ? _contrast : _standard;
  }

  static ThemeData _build(_Palette p, {required bool simplified}) {
    final text =
        p.isHighContrast ? AppTypography.highContrast : AppTypography.standard;
    final tapTarget = simplified ? minTapTargetSimplified : minTapTarget;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _scheme(p),
      scaffoldBackgroundColor: p.background,
      textTheme: text,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      shadowColor: p.shadow,
      iconTheme: IconThemeData(color: p.onBackground, size: simplified ? 32 : 28),
      appBarTheme: _appBar(p, text),
      elevatedButtonTheme: _elevatedButton(p, text, tapTarget),
      outlinedButtonTheme: _outlinedButton(p, text, tapTarget),
      textButtonTheme: _textButton(p, text, tapTarget),
      iconButtonTheme: _iconButton(tapTarget),
      inputDecorationTheme: _input(p, text, simplified),
      cardTheme: _card(p),
      dialogTheme: _dialog(p, text),
      snackBarTheme: _snackBar(p, text),
      listTileTheme: _listTile(p, text, tapTarget),
      switchTheme: _switches(p),
      sliderTheme: _slider(p, text),
      chipTheme: _chip(p, text),
      progressIndicatorTheme: _progress(p),
      dividerTheme: DividerThemeData(color: p.outlineVariant, thickness: 1),
    );
  }

  /// Seeded tonal palette with every load-bearing role overridden. The
  /// `surfaceContainer*` family is overridden too — left to the seed it would
  /// come back teal-tinted, and the warm background is a deliberate brand trait.
  static ColorScheme _scheme(_Palette p) {
    return ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      secondary: p.secondary,
      onSecondary: p.onSecondary,
      secondaryContainer: p.secondaryContainer,
      onSecondaryContainer: p.onSecondaryContainer,
      tertiary: p.tertiary,
      onTertiary: p.onTertiary,
      tertiaryContainer: p.tertiaryContainer,
      onTertiaryContainer: p.onTertiaryContainer,
      error: p.error,
      onError: p.onError,
      errorContainer: p.errorContainer,
      onErrorContainer: p.onErrorContainer,
      surface: p.surface,
      onSurface: p.onSurface,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surfaceLow,
      surfaceContainer: p.surfaceContainer,
      surfaceContainerHigh: p.surfaceContainerHigh,
      surfaceContainerHighest: p.surfaceContainerHighest,
      surfaceTint: p.primary,
      outline: p.border,
      outlineVariant: p.outlineVariant,
      shadow: p.shadow,
      inverseSurface: p.inverseSurface,
      onInverseSurface: p.onInverseSurface,
    );
  }

  static AppBarThemeData _appBar(_Palette p, TextTheme text) {
    return AppBarThemeData(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
      surfaceTintColor: Colors.transparent,
      shadowColor: p.shadow,
      elevation: AppElevation.flat,
      scrolledUnderElevation:
          p.isHighContrast ? AppElevation.flat : AppElevation.scrolledUnder,
      centerTitle: true,
      titleTextStyle: text.titleLarge?.copyWith(color: p.onPrimary),
      iconTheme: IconThemeData(color: p.onPrimary, size: 26),
      actionsIconTheme: IconThemeData(color: p.onPrimary, size: 26),
    );
  }

  static ElevatedButtonThemeData _elevatedButton(
    _Palette p,
    TextTheme text,
    double tapTarget,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        // A disabled control is exempt from WCAG contrast, but an elderly user
        // still has to read it: this pairing is 6.26:1 rather than the usual
        // washed-out grey-on-grey.
        disabledBackgroundColor: p.surfaceContainerHighest,
        disabledForegroundColor: p.textSecondary,
        minimumSize: Size(double.infinity, tapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        textStyle: text.labelLarge,
        elevation: p.isHighContrast ? AppElevation.flat : AppElevation.action,
        shadowColor: p.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.controlAll,
          side: p.isHighContrast
              ? BorderSide(color: p.border, width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButton(
    _Palette p,
    TextTheme text,
    double tapTarget,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.primary,
        backgroundColor: p.surface,
        disabledForegroundColor: p.disabled,
        minimumSize: Size(double.infinity, tapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        textStyle: text.labelLarge,
        side: BorderSide(color: p.primary, width: p.isHighContrast ? 2.5 : 1.75),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
      ),
    );
  }

  static TextButtonThemeData _textButton(
    _Palette p,
    TextTheme text,
    double tapTarget,
  ) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        minimumSize: Size(64, tapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        textStyle: text.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
      ),
    );
  }

  /// Icon buttons inherit their colour from the surrounding [IconTheme]; this
  /// only guarantees the tap target and the ripple shape.
  static IconButtonThemeData _iconButton(double tapTarget) {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: Size(tapTarget, tapTarget),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),
    );
  }

  /// Filled field with a visible outline — a filled/outlined hybrid. The label
  /// always floats, so it stays readable while the user types (low-vision
  /// users lose a label-as-placeholder the moment they enter text) and can
  /// never overlap the value.
  static InputDecorationThemeData _input(_Palette p, TextTheme text, bool simplified) {
    OutlineInputBorder side(Color color, double width) => OutlineInputBorder(
          borderRadius: AppRadius.controlAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationThemeData(
      filled: true,
      fillColor: p.surface,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: simplified ? AppSpacing.lg : AppSpacing.md,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: side(p.border, 1.5),
      enabledBorder: side(p.border, 1.5),
      focusedBorder: side(p.primary, 2.5),
      errorBorder: side(p.error, 2),
      focusedErrorBorder: side(p.error, 2.5),
      disabledBorder: side(p.outlineVariant, 1.5),
      labelStyle: text.bodyMedium?.copyWith(color: p.textSecondary),
      floatingLabelStyle:
          text.bodySmall?.copyWith(color: p.primary, fontWeight: FontWeight.w700),
      hintStyle: text.bodyMedium?.copyWith(color: p.textSecondary),
      helperStyle: text.bodySmall?.copyWith(color: p.textSecondary),
      errorStyle: text.bodySmall?.copyWith(color: p.error, fontWeight: FontWeight.w700),
      prefixIconColor: p.textSecondary,
      suffixIconColor: p.textSecondary,
    );
  }

  static CardThemeData _card(_Palette p) {
    return CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: p.shadow,
      elevation: p.isHighContrast ? AppElevation.flat : AppElevation.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: BorderSide(
          color: p.isHighContrast ? p.border : p.outlineVariant,
          width: p.isHighContrast ? 2 : 1,
        ),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static DialogThemeData _dialog(_Palette p, TextTheme text) {
    return DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.overlay,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      titleTextStyle: text.headlineMedium,
      contentTextStyle: text.bodyMedium,
    );
  }

  static SnackBarThemeData _snackBar(_Palette p, TextTheme text) {
    return SnackBarThemeData(
      backgroundColor: p.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.onInverseSurface),
      actionTextColor: p.primaryContainer,
      behavior: SnackBarBehavior.floating,
      elevation: AppElevation.overlay,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
    );
  }

  static ListTileThemeData _listTile(_Palette p, TextTheme text, double tapTarget) {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      minVerticalPadding: AppSpacing.sm,
      minTileHeight: tapTarget,
      iconColor: p.primary,
      textColor: p.onSurface,
      titleTextStyle: text.bodyLarge,
      subtitleTextStyle: text.bodySmall?.copyWith(color: p.textSecondary),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
    );
  }

  /// The off state uses a dark thumb on a light track (3.3:1) instead of
  /// Material's default light-on-light, which is close to invisible for a
  /// low-vision user trying to tell "on" from "off" at a glance.
  static SwitchThemeData _switches(_Palette p) {
    Color selected(Set<WidgetState> states, Color on, Color off) =>
        states.contains(WidgetState.selected) ? on : off;

    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => selected(states, p.onPrimary, p.border),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => selected(states, p.primary, p.surfaceContainerHighest),
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => selected(states, p.primary, p.border),
      ),
    );
  }

  static SliderThemeData _slider(_Palette p, TextTheme text) {
    return SliderThemeData(
      activeTrackColor: p.primary,
      inactiveTrackColor: p.surfaceContainerHighest,
      thumbColor: p.primary,
      overlayColor: p.primary.withValues(alpha: 0.12),
      valueIndicatorColor: p.primary,
      valueIndicatorTextStyle: text.bodySmall?.copyWith(color: p.onPrimary),
      trackHeight: 8,
    );
  }

  static ChipThemeData _chip(_Palette p, TextTheme text) {
    return ChipThemeData(
      backgroundColor: p.surfaceContainerHigh,
      selectedColor: p.primaryContainer,
      side: BorderSide(color: p.isHighContrast ? p.border : p.outlineVariant),
      labelStyle:
          text.bodySmall?.copyWith(color: p.onSurface, fontWeight: FontWeight.w700),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
    );
  }

  static ProgressIndicatorThemeData _progress(_Palette p) {
    return ProgressIndicatorThemeData(
      color: p.primary,
      linearTrackColor: p.surfaceContainerHighest,
      circularTrackColor: p.surfaceContainerHighest,
      strokeWidth: 4,
    );
  }
}

/// The resolved colour set for one theme variant.
///
/// Keeping the standard/high-contrast choice in one place means the component
/// themes above read as a single design, instead of every property carrying
/// its own `highContrast ? … : …` ternary.
@immutable
class _Palette {
  const _Palette({
    required this.isHighContrast,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.textSecondary,
    required this.border,
    required this.outlineVariant,
    required this.disabled,
    required this.shadow,
    required this.inverseSurface,
    required this.onInverseSurface,
  });

  final bool isHighContrast;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color textSecondary;
  final Color border;
  final Color outlineVariant;
  final Color disabled;
  final Color shadow;
  final Color inverseSurface;
  final Color onInverseSurface;

  static const _Palette standard = _Palette(
    isHighContrast: false,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    background: AppColors.background,
    onBackground: AppColors.onBackground,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceLow: AppColors.surfaceLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    textSecondary: AppColors.textSecondary,
    border: AppColors.border,
    outlineVariant: AppColors.outlineVariant,
    disabled: AppColors.disabled,
    shadow: AppColors.shadow,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.onInverseSurface,
  );

  /// Every pairing here clears AAA (7:1). Shadows are dropped in favour of
  /// solid black outlines, because a soft shadow conveys nothing to the users
  /// this mode exists for.
  static const _Palette contrast = _Palette(
    isHighContrast: true,
    primary: AppColors.hcPrimary,
    onPrimary: AppColors.hcOnPrimary,
    primaryContainer: AppColors.hcPrimaryContainer,
    onPrimaryContainer: AppColors.hcOnPrimaryContainer,
    secondary: AppColors.hcSecondary,
    onSecondary: AppColors.hcOnSecondary,
    secondaryContainer: AppColors.hcSecondaryContainer,
    onSecondaryContainer: AppColors.hcOnSecondaryContainer,
    tertiary: AppColors.hcTertiary,
    onTertiary: AppColors.hcOnTertiary,
    tertiaryContainer: AppColors.hcTertiaryContainer,
    onTertiaryContainer: AppColors.hcOnTertiaryContainer,
    background: AppColors.hcBackground,
    onBackground: AppColors.hcOnBackground,
    surface: AppColors.hcSurface,
    onSurface: AppColors.hcOnSurface,
    surfaceLow: AppColors.hcSurface,
    surfaceContainer: AppColors.hcSurfaceContainer,
    surfaceContainerHigh: AppColors.hcSurfaceContainer,
    surfaceContainerHighest: AppColors.hcSurfaceContainer,
    error: AppColors.hcError,
    onError: AppColors.hcOnError,
    errorContainer: AppColors.hcErrorContainer,
    onErrorContainer: AppColors.hcOnErrorContainer,
    textSecondary: AppColors.hcTextSecondary,
    border: AppColors.hcBorder,
    outlineVariant: AppColors.hcOutlineVariant,
    disabled: AppColors.hcDisabled,
    shadow: Colors.transparent,
    inverseSurface: AppColors.hcOnBackground,
    onInverseSurface: AppColors.hcBackground,
  );
}
