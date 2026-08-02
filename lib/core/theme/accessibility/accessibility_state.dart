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
  });

  /// Multiplier applied on top of the base 16sp body text. Clamped to
  /// [minTextScale, maxTextScale] by [AccessibilityController].
  final double textScale;

  /// Switches the app to [AppColors]'s high-contrast palette.
  final bool highContrast;

  /// Reduces information density: fewer items per screen, larger touch
  /// targets, simpler wording. Individual screens read this flag and adapt.
  final bool simplifiedMode;

  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.6;

  AccessibilityState copyWith({
    double? textScale,
    bool? highContrast,
    bool? simplifiedMode,
  }) {
    return AccessibilityState(
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
      simplifiedMode: simplifiedMode ?? this.simplifiedMode,
    );
  }

  Map<String, Object> toJson() => {
        'textScale': textScale,
        'highContrast': highContrast,
        'simplifiedMode': simplifiedMode,
      };

  factory AccessibilityState.fromJson(Map<String, Object?> json) {
    return AccessibilityState(
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      highContrast: json['highContrast'] as bool? ?? false,
      simplifiedMode: json['simplifiedMode'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessibilityState &&
          runtimeType == other.runtimeType &&
          textScale == other.textScale &&
          highContrast == other.highContrast &&
          simplifiedMode == other.simplifiedMode;

  @override
  int get hashCode => Object.hash(textScale, highContrast, simplifiedMode);
}
