import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';

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
      final prefs = profile.accessibilityPrefs;
      ref.read(accessibilityControllerProvider.notifier).seedFrom(
            highContrast: prefs.highContrast,
            simplifiedMode: prefs.simplifiedInterface,
            textScale: prefs.largeText ? 1.3 : 1.0,
          );
    });
  }
}

final accessibilityProfileSyncProvider =
    NotifierProvider<AccessibilityProfileSync, void>(AccessibilityProfileSync.new);
