import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';

/// One motion vocabulary for the whole app — every animation pulls its
/// duration/curve from here, the same way [AppRadius]/[AppSpacing] centralise
/// geometry. Keeps every transition feeling like part of the same app
/// instead of a pile of one-off tweens.
///
/// Timings sit inside the 150–300ms micro-interaction / ≤400ms complex-
/// transition band; nothing in this app should animate past [slow].
class AppMotion {
  const AppMotion._();

  /// Toggles, badges, small state flips.
  static const Duration fast = Duration(milliseconds: 160);

  /// Page transitions, card entrances — the default for "something moved".
  static const Duration standard = Duration(milliseconds: 240);

  /// Shared-element (Hero) transitions only.
  static const Duration slow = Duration(milliseconds: 380);

  /// Per-item delay in a staggered list entrance. 30–50ms is the range that
  /// reads as a deliberate sequence rather than "everything at once" or "one
  /// item at a time" — capped in [staggerDelayFor] so a long list doesn't
  /// keep animating for seconds after it appears.
  static const Duration staggerStep = Duration(milliseconds: 36);

  /// Entrances read as arriving into place — settle, don't overshoot.
  static const Curve enter = Curves.easeOutCubic;

  /// Exits get out of the way faster than they came in (≈65% of [standard]),
  /// so dismissing something never feels like it's dragging its feet.
  static const Curve exit = Curves.easeInCubic;
  static const Duration exitStandard = Duration(milliseconds: 160);

  /// Per-item delay for a staggered entrance, capped so item 40 in a long
  /// list doesn't animate in half a second after item 1 — beyond ~10 items
  /// the whole list should have finished settling.
  static Duration staggerDelayFor(int index) {
    final capped = index.clamp(0, 10);
    return staggerStep * capped;
  }

  /// Whether motion should be minimised: the OS-level "reduce motion"
  /// accessibility setting, or this app's own Simplified Mode (which already
  /// promises a calmer, less busy screen — animated flourishes would
  /// contradict that promise for the users who turn it on).
  ///
  /// Every non-essential animation in the app should check this first and
  /// skip straight to its end state rather than trying to animate a shorter
  /// version — a user who asked for less motion should get *no* motion, not
  /// a smaller amount of it.
  ///
  /// Uses `ref.read` rather than `ref.watch` deliberately: this is checked
  /// once, at the moment an animation is about to start (build or
  /// `initState`, where `watch` would assert) — a one-shot entrance doesn't
  /// need to react to the setting changing mid-flight.
  static bool reduced(BuildContext context, WidgetRef ref) {
    if (MediaQuery.of(context).disableAnimations) return true;
    return ref.read(
      accessibilityControllerProvider.select((s) => s.simplifiedMode),
    );
  }
}
