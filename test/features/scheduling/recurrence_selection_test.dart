import 'package:elderly_companion/features/scheduling/domain/entities/recurrence_rule.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/recurring_booking_result.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/services/recurrence_selection.dart';
import 'package:elderly_companion/features/scheduling/presentation/widgets/recurrence_picker.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pure half of the booking form's repeat option: which rule the picked
/// days produce, and what the user is told afterwards. No widgets pumped —
/// see the note in the chunk summary about widget-test precedent.
void main() {
  const selection = RecurrenceSelection();

  // A Tuesday, 10:00.
  final tuesday = DateTime(2026, 9, 1, 10, 0);

  group('effectiveDays', () {
    test('uses the picked days when there are any', () {
      expect(
        selection.effectiveDays(
          days: {RecurrenceDay.monday, RecurrenceDay.thursday},
          anchor: tuesday,
        ),
        {RecurrenceDay.monday, RecurrenceDay.thursday},
      );
    });

    test('falls back to the weekday of the chosen date when none are picked',
        () {
      expect(
        selection.effectiveDays(days: const {}, anchor: tuesday),
        {RecurrenceDay.tuesday},
      );
    });

    test('the fallback follows the chosen date, not the calendar', () {
      expect(
        selection.effectiveDays(
          days: const {},
          anchor: DateTime(2026, 9, 5, 9, 0), // a Saturday
        ),
        {RecurrenceDay.saturday},
      );
    });
  });

  group('ruleFor', () {
    test('builds a weekly rule on the picked days', () {
      final rule = selection.ruleFor(
        days: {RecurrenceDay.monday, RecurrenceDay.wednesday},
        anchor: tuesday,
      );

      expect(rule.frequency, RecurrenceFrequency.weekly);
      expect(rule.interval, 1);
      expect(rule.toRuleString(), 'FREQ=WEEKLY;BYDAY=MO,WE');
    });

    test('builds a rule on the anchor weekday when nothing is picked', () {
      expect(
        selection.ruleFor(days: const {}, anchor: tuesday).toRuleString(),
        'FREQ=WEEKLY;BYDAY=TU',
      );
    });

    test('never produces a daily or intervalled rule', () {
      for (final days in [
        <RecurrenceDay>{},
        {RecurrenceDay.sunday},
        RecurrenceDay.values.toSet(),
      ]) {
        final rule = selection.ruleFor(days: days, anchor: tuesday);
        expect(rule.frequency, RecurrenceFrequency.weekly);
        expect(rule.interval, 1);
      }
    });

    test('produces occurrences on exactly the picked days', () {
      final rule = selection.ruleFor(
        days: {RecurrenceDay.tuesday, RecurrenceDay.friday},
        anchor: tuesday,
      );

      expect(
        rule.nextOccurrences(from: tuesday, count: 4),
        [
          DateTime(2026, 9, 1, 10, 0), // Tue
          DateTime(2026, 9, 4, 10, 0), // Fri
          DateTime(2026, 9, 8, 10, 0), // Tue
          DateTime(2026, 9, 11, 10, 0), // Fri
        ],
      );
    });
  });

  group('describe', () {
    test('names a single day', () {
      expect(
        selection.describe(days: {RecurrenceDay.tuesday}, anchor: tuesday),
        'Every Tuesday',
      );
    });

    test('joins two days with "and"', () {
      expect(
        selection.describe(
          days: {RecurrenceDay.thursday, RecurrenceDay.monday},
          anchor: tuesday,
        ),
        'Every Monday and Thursday',
      );
    });

    test('lists three or more in weekday order', () {
      expect(
        selection.describe(
          days: {
            RecurrenceDay.friday,
            RecurrenceDay.monday,
            RecurrenceDay.wednesday,
          },
          anchor: tuesday,
        ),
        'Every Monday, Wednesday and Friday',
      );
    });

    test('describes the fallback day when nothing is picked', () {
      expect(
        selection.describe(days: const {}, anchor: tuesday),
        'Every Tuesday',
      );
    });
  });

  group('recurringBookingMessage', () {
    Session session(int day) => Session(
          id: 'session-$day',
          requesterId: 'elder-1',
          volunteerId: 'volunteer-1',
          scheduledAt: DateTime(2026, 9, day, 10, 0),
          durationMinutes: 60,
          status: SessionStatus.requested,
          location: 'Community centre',
          isRecurring: true,
          seriesId: 'series-1',
        );

    test('reports the count when the whole series was booked', () {
      final result = RecurringBookingResult(
        seriesId: 'series-1',
        sessions: [session(1), session(8), session(15)],
        skippedOccurrences: const [],
      );

      expect(recurringBookingMessage(result), 'Booked 3 repeating sessions.');
    });

    test('reads naturally for a one-occurrence series', () {
      final result = RecurringBookingResult(
        seriesId: 'series-1',
        sessions: [session(1)],
        skippedOccurrences: const [],
      );

      expect(recurringBookingMessage(result), 'Session booked.');
    });

    test('does not claim success when occurrences were skipped', () {
      final result = RecurringBookingResult(
        seriesId: 'series-1',
        sessions: [session(1), session(8)],
        skippedOccurrences: [
          DateTime(2026, 9, 15, 10, 0),
          DateTime(2026, 9, 22, 10, 0),
        ],
      );

      final message = recurringBookingMessage(result);

      expect(message, contains('Booked 2 of 4 sessions'));
      expect(message, contains('2 could not be created'));
      expect(message, contains('dates'));
    });

    test('uses the singular for a single skipped date', () {
      final result = RecurringBookingResult(
        seriesId: 'series-1',
        sessions: [session(1), session(8)],
        skippedOccurrences: [DateTime(2026, 9, 15, 10, 0)],
      );

      final message = recurringBookingMessage(result);

      expect(message, contains('Booked 2 of 3 sessions'));
      expect(message, contains('missing date'));
    });
  });

  group('RecurrenceDay labels', () {
    test('carries a full and a short label for every day', () {
      expect(RecurrenceDay.monday.label, 'Monday');
      expect(RecurrenceDay.monday.shortLabel, 'Mon');
      expect(RecurrenceDay.sunday.shortLabel, 'Sun');
      for (final day in RecurrenceDay.values) {
        expect(day.shortLabel.length, 3);
      }
    });
  });
}
