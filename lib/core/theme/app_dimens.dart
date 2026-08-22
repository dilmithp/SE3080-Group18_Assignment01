import 'package:flutter/material.dart';

/// Corner-radius scale. Every rounded surface in the app pulls from here so
/// the geometry stays consistent — no magic numbers at call sites.
class AppRadius {
  const AppRadius._();

  /// Chips, small badges, icon tiles.
  static const double small = 10;

  /// Buttons, inputs, dropdowns — anything the user acts on directly.
  static const double control = 14;

  /// Cards, sheets, dialogs, tinted panels.
  static const double card = 20;

  /// Fully rounded (pills, avatars, status badges).
  static const double pill = 999;

  static const BorderRadius smallAll = BorderRadius.all(Radius.circular(small));
  static const BorderRadius controlAll =
      BorderRadius.all(Radius.circular(control));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// 8dp spacing rhythm. `xs` is the only half-step, used for tight label/value
/// pairs where a full 8dp would break the visual grouping.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  /// Default horizontal gutter for scrollable screen bodies.
  static const EdgeInsets screen = EdgeInsets.all(md);

  /// Roomier gutter for single-column form/marketing layouts.
  static const EdgeInsets screenWide = EdgeInsets.all(lg);
}

/// Layout limits. This app runs on the web as well as on phones, and a form
/// stretched across a 1400px desktop window is unreadable — worse for someone
/// tracking a line of text with reduced vision.
class AppLayout {
  const AppLayout._();

  /// Forms, cards and single-column screen bodies.
  static const double maxContentWidth = 520;

  /// Centred prose (empty/error/loading states, splash copy).
  static const double maxProseWidth = 420;
}

/// One elevation scale for the whole app. High-contrast mode collapses these
/// to zero and substitutes solid borders, because soft shadows are invisible
/// to the users that mode exists for.
class AppElevation {
  const AppElevation._();

  static const double flat = 0;

  /// Resting cards and tinted panels.
  static const double card = 2;

  /// Primary call-to-action buttons.
  static const double action = 3;

  /// App bar once content scrolls beneath it.
  static const double scrolledUnder = 3;

  /// Dialogs, menus, snackbars.
  static const double overlay = 6;
}
