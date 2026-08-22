import 'package:elderly_companion/core/theme/accessibility/accessibility_state.dart';
import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/accessibility_profile_sync.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the pure field-mapping functions AccessibilityProfileSync (the
/// seed-on-sign-in direction) and AccessibilitySettingsScreen (the
/// write-through direction) both depend on. The two shapes don't match
/// 1:1 — this is what makes that mapping worth testing directly rather
/// than trusting it by inspection.
void main() {
  group('mapPreferencesToAccessibilityState', () {
    test('maps highContrast and simplifiedInterface straight through', () {
      const prefs = AccessibilityPreferences(
        largeText: false,
        highContrast: true,
        simplifiedInterface: true,
      );

      final mapped = mapPreferencesToAccessibilityState(prefs);

      expect(mapped.highContrast, isTrue);
      expect(mapped.simplifiedMode, isTrue);
    });

    test('largeText true maps to the 1.3 "Large" preset', () {
      const prefs = AccessibilityPreferences(
        largeText: true,
        highContrast: false,
        simplifiedInterface: false,
      );

      expect(mapPreferencesToAccessibilityState(prefs).textScale, 1.3);
    });

    test('largeText false maps to the 1.0 standard scale', () {
      const prefs = AccessibilityPreferences(
        largeText: false,
        highContrast: false,
        simplifiedInterface: false,
      );

      expect(mapPreferencesToAccessibilityState(prefs).textScale, 1.0);
    });
  });

  group('mapAccessibilityStateToPreferences', () {
    const existing = AccessibilityPreferences(
      largeText: false,
      highContrast: false,
      simplifiedInterface: false,
      communicationNotes: 'Speaks slowly, prefers texting.',
    );

    test('textScale above 1.0 maps to largeText true', () {
      const state = AccessibilityState(textScale: 1.5);

      final mapped = mapAccessibilityStateToPreferences(state, existing);

      expect(mapped.largeText, isTrue);
    });

    test('textScale of exactly 1.0 maps to largeText false', () {
      const state = AccessibilityState();

      expect(mapAccessibilityStateToPreferences(state, existing).largeText, isFalse);
    });

    test('highContrast and simplifiedMode map straight through', () {
      const state = AccessibilityState(highContrast: true, simplifiedMode: true);

      final mapped = mapAccessibilityStateToPreferences(state, existing);

      expect(mapped.highContrast, isTrue);
      expect(mapped.simplifiedInterface, isTrue);
    });

    test('preserves communicationNotes from the existing preferences unchanged', () {
      const state = AccessibilityState(highContrast: true);

      final mapped = mapAccessibilityStateToPreferences(state, existing);

      expect(mapped.communicationNotes, 'Speaks slowly, prefers texting.');
    });
  });
}
