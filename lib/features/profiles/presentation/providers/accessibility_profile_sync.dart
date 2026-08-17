import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_state.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';

/// Persisted → local direction of the field mapping (see class doc below
/// for why these two shapes don't line up 1:1). Pure and dependency-free
/// so it's unit-testable without mocking Riverpod or Firebase — see
/// test/features/profiles/accessibility_mapping_test.dart.
({bool highContrast, bool simplifiedMode, double textScale})
    mapPreferencesToAccessibilityState(AccessibilityPreferences prefs) {
  return (
    highContrast: prefs.highContrast,
    simplifiedMode: prefs.simplifiedInterface,
    // largeText is a bool; textScale is continuous. 1.3 is the same
    // "Large" preset AccessibilitySettingsScreen's quick-picker offers, so
    // seeding from a profile lands on a value the user could have chosen
    // themselves rather than an arbitrary number.
    textScale: prefs.largeText ? 1.3 : 1.0,
  );
}

/// Local → persisted direction, used by AccessibilitySettingsScreen's
/// write-through. [existing] supplies `communicationNotes`, which has no
/// local counterpart and must pass through unchanged.
AccessibilityPreferences mapAccessibilityStateToPreferences(
  AccessibilityState state,
  AccessibilityPreferences existing,
) {
  return AccessibilityPreferences(
    largeText: state.textScale > 1.0,
    highContrast: state.highContrast,
    simplifiedInterface: state.simplifiedMode,
    communicationNotes: existing.communicationNotes,
  );
}

/// One-way sync from the signed-in user's persisted
/// `UserProfile.accessibilityPrefs` into the on-device
/// [AccessibilityController]: the moment a profile first loads for a
/// session, its accessibility fields seed the local controller so
/// preferences follow the user to a new device instead of resetting to
/// defaults. After that single seed, local toggles are the source of
/// truth for the rest of the session — [AccessibilitySettingsScreen] writes
/// them back to the profile itself, so this class does not need to react to
/// every subsequent profile update (that would just be echoing the write it
/// caused).
///
/// Lives in features/profiles (not core/theme) because only this feature
/// knows about [AccessibilityPreferences] / [ProfileRepository] —
/// [AccessibilityController] stays free of any profiles-domain import and
/// only ever sees the three mapped primitives.
class AccessibilityProfileSync extends Notifier<void> {
  String? _seededForUserId;

  @override
  void build() {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    if (userId == null) {
      _seededForUserId = null;
      return;
    }

    ref.listen(profileProvider(userId), (previous, next) {
      if (_seededForUserId == userId) return;
      final profile = next.valueOrNull;
      if (profile == null) return;

      _seededForUserId = userId;
      final mapped = mapPreferencesToAccessibilityState(profile.accessibilityPrefs);
      ref.read(accessibilityControllerProvider.notifier).seedFrom(
            highContrast: mapped.highContrast,
            simplifiedMode: mapped.simplifiedMode,
            textScale: mapped.textScale,
          );
    });
  }
}

final accessibilityProfileSyncProvider =
    NotifierProvider<AccessibilityProfileSync, void>(AccessibilityProfileSync.new);
