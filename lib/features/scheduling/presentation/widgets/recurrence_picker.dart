import 'package:flutter/material.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/recurrence_rule.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/recurring_booking_result.dart';
import 'package:elderly_companion/features/scheduling/domain/services/recurrence_selection.dart';

/// "Repeat this session" for a booking form: a switch, and — once it is on —
/// the days of the week to repeat on.
///
/// Off by default is the caller's job (this widget is controlled), and it is
/// the right default: most bookings are one-off, and a one-off booking
/// should stay the shortest path through the form.
///
/// Weekly only. Daily and every-n-weeks are deliberately not offered — see
/// [RecurrenceSelection] for why, and for what widening it would take.
///
/// Owner: Ranketh (features/scheduling).
class RecurrencePicker extends StatelessWidget {
  const RecurrencePicker({
    required this.isRepeating,
    required this.selectedDays,
    required this.anchor,
    required this.onRepeatingChanged,
    required this.onDaysChanged,
    this.enabled = true,
    super.key,
  });

  /// Whether the switch is on.
  final bool isRepeating;

  /// Days the user has picked. Empty is valid: the summary and the rule then
  /// fall back to [anchor]'s own weekday.
  final Set<RecurrenceDay> selectedDays;

  /// The date/time already chosen in the form — supplies the fallback day.
  final DateTime anchor;

  final ValueChanged<bool> onRepeatingChanged;
  final ValueChanged<Set<RecurrenceDay>> onDaysChanged;

  /// Set false while a booking is in flight, so the schedule cannot be
  /// changed underneath a submit that has already been sent.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const selection = RecurrenceSelection();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile.adaptive(
          value: isRepeating,
          onChanged: enabled ? onRepeatingChanged : null,
          contentPadding: EdgeInsets.zero,
          title: const Text('Repeat this session'),
          subtitle: const Text('Book the same time every week'),
          secondary: Icon(Icons.repeat, color: theme.colorScheme.primary),
        ),
        if (isRepeating) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Which days?', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final day in RecurrenceDay.values)
                FilterChip(
                  // The full day name carries the semantics; the chip shows
                  // three letters so seven of them fit a phone width.
                  label: Text(day.shortLabel),
                  tooltip: day.label,
                  selected: selectedDays.contains(day),
                  onSelected: enabled ? (_) => _toggle(day) : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            selection.describe(days: selectedDays, anchor: anchor),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  void _toggle(RecurrenceDay day) {
    final next = {...selectedDays};
    if (!next.remove(day)) next.add(day);
    onDaysChanged(next);
  }
}

/// What to tell someone after a recurring booking run.
///
/// A partly-written series gets its own wording rather than the success
/// text: [RecurringBookingResult] can come back with occurrences missing,
/// and "Booked 8 sessions" over the top of that would hide a gap the person
/// would only discover later, looking at a calendar.
///
/// Pure — no [BuildContext] — so the wording is unit-testable.
String recurringBookingMessage(RecurringBookingResult result) {
  final booked = result.sessions.length;

  if (result.isComplete) {
    return booked == 1
        ? 'Session booked.'
        : 'Booked $booked repeating sessions.';
  }

  final skipped = result.skippedOccurrences.length;
  return 'Booked $booked of ${result.requestedCount} sessions — '
      '$skipped could not be created. Check your calendar and rebook the '
      'missing ${skipped == 1 ? 'date' : 'dates'}.';
}
