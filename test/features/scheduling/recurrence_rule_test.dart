import 'package:elderly_companion/features/scheduling/domain/entities/recurrence_rule.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-domain tests — no Firestore, no Session, no widgets. The rule string
/// is free text on a document any client can write, so the malformed cases
/// matter as much as the happy path.
void main() {
  // A Tuesday, 10:00.
  final tuesday = DateTime(2026, 9, 1, 10, 0);

  group('tryParse — valid strings', () {
    test('parses the weekly single-day form used elsewhere in the feature', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY;BYDAY=TU');

      expect(rule, isNotNull);
      expect(rule!.frequency, RecurrenceFrequency.weekly);
      expect(rule.interval, 1);
      expect(rule.days, {RecurrenceDay.tuesday});
    });

    test('defaults interval to 1 when omitted', () {
      expect(RecurrenceRule.tryParse('FREQ=DAILY')!.interval, 1);
    });

    test('parses an interval greater than 1', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE');

      expect(rule!.interval, 2);
      expect(rule.days, {RecurrenceDay.monday, RecurrenceDay.wednesday});
    });

    test('accepts the parts in any order', () {
      expect(
        RecurrenceRule.tryParse('BYDAY=FR;INTERVAL=3;FREQ=WEEKLY'),
        RecurrenceRule.tryParse('FREQ=WEEKLY;INTERVAL=3;BYDAY=FR'),
      );
    });

    test('is case-insensitive and tolerates surrounding whitespace', () {
      expect(
        RecurrenceRule.tryParse('  freq=weekly ; byday=mo,we  '),
        RecurrenceRule.tryParse('FREQ=WEEKLY;BYDAY=MO,WE'),
      );
    });

    test('accepts a weekly rule with no BYDAY', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY');

      expect(rule!.days, isEmpty);
      expect(rule.frequency, RecurrenceFrequency.weekly);
    });
  });

  group('tryParse — malformed strings return null, never throw', () {
    const malformed = <String, String?>{
      'null input': null,
      'empty': '',
      'blank': '   ',
      'missing FREQ': 'INTERVAL=2;BYDAY=MO',
      'unknown frequency': 'FREQ=MONTHLY',
      'unknown key': 'FREQ=WEEKLY;UNTIL=20261231',
      'unknown day code': 'FREQ=WEEKLY;BYDAY=MO,XX',
      'empty BYDAY': 'FREQ=WEEKLY;BYDAY=',
      'non-numeric interval': 'FREQ=WEEKLY;INTERVAL=two',
      'zero interval': 'FREQ=WEEKLY;INTERVAL=0',
      'negative interval': 'FREQ=WEEKLY;INTERVAL=-2',
      'BYDAY on a daily rule': 'FREQ=DAILY;BYDAY=MO',
      'duplicate FREQ': 'FREQ=WEEKLY;FREQ=DAILY',
      'no separator': 'FREQ=WEEKLY;INTERVAL',
      'empty part': 'FREQ=WEEKLY;;BYDAY=MO',
      'value with no key': 'FREQ=WEEKLY;=MO',
      'just a semicolon': ';',
      'free text': 'every other tuesday',
    };

    malformed.forEach((label, input) {
      test(label, () {
        expect(
          () => RecurrenceRule.tryParse(input),
          returnsNormally,
          reason: 'parsing must never throw on corrupt input',
        );
        expect(RecurrenceRule.tryParse(input), isNull);
      });
    });
  });

  group('nextOccurrences — weekly', () {
    test('repeats on the BYDAY weekday, including the anchor itself', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY;BYDAY=TU')!;

      expect(
        rule.nextOccurrences(from: tuesday, count: 3),
        [
          DateTime(2026, 9, 1, 10, 0),
          DateTime(2026, 9, 8, 10, 0),
          DateTime(2026, 9, 15, 10, 0),
        ],
      );
    });

    test('honours an interval greater than 1', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY;INTERVAL=2;BYDAY=TU')!;

      expect(
        rule.nextOccurrences(from: tuesday, count: 3),
        [
          DateTime(2026, 9, 1, 10, 0),
          DateTime(2026, 9, 15, 10, 0),
          DateTime(2026, 9, 29, 10, 0),
        ],
      );
    });

    test('walks multiple BYDAY values in weekday order', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY;BYDAY=MO,WE,FR')!;
      // Anchored on a Tuesday: that week's Monday is already past, so the
      // series starts on the Wednesday.
      expect(
        rule.nextOccurrences(from: tuesday, count: 5),
        [
          DateTime(2026, 9, 2, 10, 0), // Wed
          DateTime(2026, 9, 4, 10, 0), // Fri
          DateTime(2026, 9, 7, 10, 0), // Mon
          DateTime(2026, 9, 9, 10, 0), // Wed
          DateTime(2026, 9, 11, 10, 0), // Fri
        ],
      );
    });

    test('combines multiple BYDAY values with an interval', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE')!;
      final monday = DateTime(2026, 8, 31, 9, 30);

      expect(
        rule.nextOccurrences(from: monday, count: 4),
        [
          DateTime(2026, 8, 31, 9, 30), // Mon, anchor week
          DateTime(2026, 9, 2, 9, 30), // Wed, anchor week
          DateTime(2026, 9, 14, 9, 30), // Mon, two weeks later
          DateTime(2026, 9, 16, 9, 30), // Wed
        ],
      );
    });

    test('falls back to the anchor weekday when BYDAY is absent', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY')!;

      expect(
        rule.nextOccurrences(from: tuesday, count: 2),
        [DateTime(2026, 9, 1, 10, 0), DateTime(2026, 9, 8, 10, 0)],
      );
    });

    test('keeps the anchor time of day, minutes included', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY;BYDAY=SU')!;
      final sunday = DateTime(2026, 9, 6, 16, 45);

      expect(
        rule.nextOccurrences(from: sunday, count: 2),
        [DateTime(2026, 9, 6, 16, 45), DateTime(2026, 9, 13, 16, 45)],
      );
    });

    test('crosses a month boundary correctly', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY;BYDAY=TU')!;

      expect(
        rule.nextOccurrences(from: DateTime(2026, 9, 29, 10, 0), count: 2),
        [DateTime(2026, 9, 29, 10, 0), DateTime(2026, 10, 6, 10, 0)],
      );
    });
  });

  group('nextOccurrences — daily', () {
    test('repeats every day from the anchor', () {
      final rule = RecurrenceRule.tryParse('FREQ=DAILY')!;

      expect(
        rule.nextOccurrences(from: tuesday, count: 3),
        [
          DateTime(2026, 9, 1, 10, 0),
          DateTime(2026, 9, 2, 10, 0),
          DateTime(2026, 9, 3, 10, 0),
        ],
      );
    });

    test('honours an interval, crossing a month boundary', () {
      final rule = RecurrenceRule.tryParse('FREQ=DAILY;INTERVAL=3')!;

      expect(
        rule.nextOccurrences(from: DateTime(2026, 9, 28, 8, 0), count: 3),
        [
          DateTime(2026, 9, 28, 8, 0),
          DateTime(2026, 10, 1, 8, 0),
          DateTime(2026, 10, 4, 8, 0),
        ],
      );
    });
  });

  group('nextOccurrences — edges', () {
    test('a non-positive count yields nothing', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY;BYDAY=TU')!;

      expect(rule.nextOccurrences(from: tuesday, count: 0), isEmpty);
      expect(rule.nextOccurrences(from: tuesday, count: -1), isEmpty);
    });

    test('returns exactly the requested count for a dense rule', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU')!;

      expect(rule.nextOccurrences(from: tuesday, count: 10).length, 10);
    });

    test('a UTC anchor yields UTC occurrences', () {
      final rule = RecurrenceRule.tryParse('FREQ=DAILY')!;
      final anchor = DateTime.utc(2026, 9, 1, 10, 0);

      final occurrences = rule.nextOccurrences(from: anchor, count: 2);

      expect(occurrences.every((o) => o.isUtc), isTrue);
      expect(occurrences.last, DateTime.utc(2026, 9, 2, 10, 0));
    });

    test('occurrences are strictly increasing', () {
      final rule = RecurrenceRule.tryParse('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,TH')!;
      final occurrences = rule.nextOccurrences(from: tuesday, count: 8);

      for (var i = 1; i < occurrences.length; i++) {
        expect(
          occurrences[i].isAfter(occurrences[i - 1]),
          isTrue,
          reason: '${occurrences[i]} should follow ${occurrences[i - 1]}',
        );
      }
    });
  });

  group('toRuleString', () {
    test('omits a default interval and an empty BYDAY', () {
      expect(
        const RecurrenceRule(frequency: RecurrenceFrequency.weekly).toRuleString(),
        'FREQ=WEEKLY',
      );
    });

    test('emits BYDAY in weekday order regardless of set order', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        days: {RecurrenceDay.friday, RecurrenceDay.monday},
      );

      expect(rule.toRuleString(), 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR');
    });

    test('round-trips through tryParse', () {
      for (final input in [
        'FREQ=DAILY',
        'FREQ=DAILY;INTERVAL=4',
        'FREQ=WEEKLY',
        'FREQ=WEEKLY;BYDAY=TU',
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,SA',
      ]) {
        final rule = RecurrenceRule.tryParse(input)!;
        expect(rule.toRuleString(), input);
        expect(RecurrenceRule.tryParse(rule.toRuleString()), rule);
      }
    });
  });

  group('value semantics', () {
    test('equal rules compare equal regardless of BYDAY set order', () {
      const a = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        days: {RecurrenceDay.monday, RecurrenceDay.friday},
      );
      const b = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        days: {RecurrenceDay.friday, RecurrenceDay.monday},
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differing interval or days are not equal', () {
      const weekly = RecurrenceRule(frequency: RecurrenceFrequency.weekly);
      const fortnightly = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
      );

      expect(weekly, isNot(fortnightly));
      expect(
        weekly,
        isNot(const RecurrenceRule(frequency: RecurrenceFrequency.daily)),
      );
    });
  });

  group('RecurrenceDay', () {
    test('maps codes to DateTime weekday constants', () {
      expect(RecurrenceDay.fromCode('MO')!.weekday, DateTime.monday);
      expect(RecurrenceDay.fromCode('SU')!.weekday, DateTime.sunday);
      expect(RecurrenceDay.fromCode('ZZ'), isNull);
      expect(RecurrenceDay.fromWeekday(DateTime.thursday), RecurrenceDay.thursday);
    });
  });
}
