import 'package:elderly_companion/core/theme/accessibility/accessibility_state.dart';
import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/accessibility_profile_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const existing = AccessibilityPreferences(
    largeText: false,
    highContrast: false,
    simplifiedInterface: false,
  );

  group('text scale round trip', () {
    test('a saved scale of 1.6 is restored as 1.6, not the 1.3 preset', () {
      final saved = mapAccessibilityStateToPreferences(
        const AccessibilityState(textScale: 1.6),
        existing,
      );

      final restored = mapPreferencesToAccessibilityState(saved);

      expect(restored.textScale, 1.6);
    });

    test('a scale of 1.1 survives the round trip', () {
      final saved = mapAccessibilityStateToPreferences(
        const AccessibilityState(textScale: 1.1),
        existing,
      );

      expect(mapPreferencesToAccessibilityState(saved).textScale, 1.1);
    });

    test('a profile saved before textScale existed still uses largeText', () {
      const legacyLarge = AccessibilityPreferences(
        largeText: true,
        highContrast: false,
        simplifiedInterface: false,
      );
      const legacyStandard = AccessibilityPreferences(
        largeText: false,
        highContrast: false,
        simplifiedInterface: false,
      );

      expect(mapPreferencesToAccessibilityState(legacyLarge).textScale, 1.3);
      expect(mapPreferencesToAccessibilityState(legacyStandard).textScale, 1.0);
    });

    test('copyWith keeps textScale unless it is changed', () {
      const prefs = AccessibilityPreferences(
        largeText: true,
        highContrast: false,
        simplifiedInterface: false,
        textScale: 1.4,
      );

      expect(prefs.copyWith(highContrast: true).textScale, 1.4);
    });
  });
}
