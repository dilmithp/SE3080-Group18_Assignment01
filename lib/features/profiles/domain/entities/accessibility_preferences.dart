/// Pure domain entity — zero `package:firebase_*` imports.
///
/// The user's *stored* accessibility preferences, synced to their profile
/// document so they follow the user across devices. This is distinct from
/// `core/theme/accessibility`'s `AccessibilityState`, which is local,
/// on-device UI state (not persisted to Firestore) — that state is typically
/// seeded from this entity on app start, but the two are not the same type.
class AccessibilityPreferences {
  const AccessibilityPreferences({
    required this.largeText,
    required this.highContrast,
    required this.simplifiedInterface,
    this.communicationNotes,
  });

  final bool largeText;
  final bool highContrast;
  final bool simplifiedInterface;
  final String? communicationNotes;

  AccessibilityPreferences copyWith({
    bool? largeText,
    bool? highContrast,
    bool? simplifiedInterface,
    String? communicationNotes,
  }) {
    return AccessibilityPreferences(
      largeText: largeText ?? this.largeText,
      highContrast: highContrast ?? this.highContrast,
      simplifiedInterface: simplifiedInterface ?? this.simplifiedInterface,
      communicationNotes: communicationNotes ?? this.communicationNotes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessibilityPreferences &&
          runtimeType == other.runtimeType &&
          largeText == other.largeText &&
          highContrast == other.highContrast &&
          simplifiedInterface == other.simplifiedInterface &&
          communicationNotes == other.communicationNotes;

  @override
  int get hashCode =>
      Object.hash(largeText, highContrast, simplifiedInterface, communicationNotes);
}
