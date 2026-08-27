import 'package:elderly_companion/features/scheduling/domain/entities/recurrence_rule.dart';

/// Turns what someone picked in a booking form into a [RecurrenceRule].
///
/// Pure Dart, so the rule a booking form produces can be asserted without
/// pumping a widget — the same reason [SessionConflictDetector] and
/// [FeedbackEligibility] live in this folder.
///
/// Weekly only for now: a companionship check-in repeats on chosen days of
/// the week, and offering daily or every-n-weeks would be more dials than
/// that needs. [RecurrenceRule] already parses and expands `FREQ=DAILY` and
/// `INTERVAL=n`, so widening this is a change here and in the picker, not in
/// the recurrence logic.
///
/// Owner: Ranketh (features/scheduling).
class RecurrenceSelection {
  const RecurrenceSelection();

  /// The days a rule built from [days] would actually fall on.
  ///
  /// An empty selection falls back to the weekday of [anchor] — the date
  /// already chosen in the form — so "repeat this" always has a defined
  /// meaning even before anyone touches the day chips, and a form can never
  /// submit a repeat with no days at all.
  Set<RecurrenceDay> effectiveDays({
    required Set<RecurrenceDay> days,
    required DateTime anchor,
  }) {
    if (days.isNotEmpty) return days;
    return {RecurrenceDay.fromWeekday(anchor.weekday)};
  }

  /// The weekly rule for [days], anchored on [anchor].
  RecurrenceRule ruleFor({
    required Set<RecurrenceDay> days,
    required DateTime anchor,
  }) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      days: effectiveDays(days: days, anchor: anchor),
    );
  }

  /// "Every Tuesday", "Every Monday and Thursday", "Every Monday, Wednesday
  /// and Friday" — days in weekday order, so the sentence reads the way a
  /// week does.
  String describe({
    required Set<RecurrenceDay> days,
    required DateTime anchor,
  }) {
    final ordered = effectiveDays(days: days, anchor: anchor).toList()
      ..sort((a, b) => a.weekday.compareTo(b.weekday));
    final names = ordered.map((day) => day.label).toList();

    if (names.length == 1) return 'Every ${names.single}';
    final last = names.removeLast();
    return 'Every ${names.join(', ')} and $last';
  }
}
