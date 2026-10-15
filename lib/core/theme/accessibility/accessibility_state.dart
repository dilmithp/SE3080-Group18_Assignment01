/// Immutable snapshot of the user's accessibility preferences.
///
/// Hand-written (not freezed) — this is a tiny, stable value type read on
/// almost every frame via [AccessibilityController], so it stays dependency
/// free and needs no code generation.
class AccessibilityState {
  const AccessibilityState({
    this.textScale = 1.0,
    this.highContrast = false,
    this.simplifiedMode = false,
    this.voiceGuidedPrompts = false,
    this.reducedMotion = false,
    this.dataSaver = false,
    this.locale = 'en',
  });

  /// Multiplier applied on top of the base 16sp body text. Clamped to
  /// [minTextScale, maxTextScale] by [AccessibilityController].
  final double textScale;

  /// Switches the app to [AppColors]'s high-contrast palette.
  final bool highContrast;

  /// Reduces information density: fewer items per screen, larger touch
  /// targets, simpler wording. Individual screens read this flag and adapt.
  final bool simplifiedMode;

  /// Enables voice-guided prompt descriptions and audio cues for screen elements.
  final bool voiceGuidedPrompts;

  /// Disables all decorative animations in the app regardless of the OS setting.
  /// This is a separate toggle from [simplifiedMode] and the OS "reduce motion"
  /// system setting so users have explicit per-app control.
  final bool reducedMotion;

  /// When true, profile photo uploads are compressed more aggressively and
  /// images in list views are replaced by placeholders to reduce data use.
  final bool dataSaver;

  /// BCP-47 language tag for the app UI locale (e.g. 'en', 'si', 'ta').
  final String locale;

  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.6;

  AccessibilityState copyWith({
    double? textScale,
    bool? highContrast,
    bool? simplifiedMode,
    bool? voiceGuidedPrompts,
    bool? reducedMotion,
    bool? dataSaver,
    String? locale,
  }) {
    return AccessibilityState(
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
      simplifiedMode: simplifiedMode ?? this.simplifiedMode,
      voiceGuidedPrompts: voiceGuidedPrompts ?? this.voiceGuidedPrompts,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      dataSaver: dataSaver ?? this.dataSaver,
      locale: locale ?? this.locale,
    );
  }

  Map<String, Object> toJson() => {
        'textScale': textScale,
        'highContrast': highContrast,
        'simplifiedMode': simplifiedMode,
        'voiceGuidedPrompts': voiceGuidedPrompts,
        'reducedMotion': reducedMotion,
        'dataSaver': dataSaver,
        'locale': locale,
      };

  factory AccessibilityState.fromJson(Map<String, Object?> json) {
    return AccessibilityState(
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      highContrast: json['highContrast'] as bool? ?? false,
      simplifiedMode: json['simplifiedMode'] as bool? ?? false,
      voiceGuidedPrompts: json['voiceGuidedPrompts'] as bool? ?? false,
      reducedMotion: json['reducedMotion'] as bool? ?? false,
      dataSaver: json['dataSaver'] as bool? ?? false,
      locale: json['locale'] as String? ?? 'en',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessibilityState &&
          runtimeType == other.runtimeType &&
          textScale == other.textScale &&
          highContrast == other.highContrast &&
          simplifiedMode == other.simplifiedMode &&
          voiceGuidedPrompts == other.voiceGuidedPrompts &&
          reducedMotion == other.reducedMotion &&
          dataSaver == other.dataSaver &&
          locale == other.locale;

  @override
  int get hashCode => Object.hash(
        textScale,
        highContrast,
        simplifiedMode,
        voiceGuidedPrompts,
        reducedMotion,
        dataSaver,
        locale,
      );
}
