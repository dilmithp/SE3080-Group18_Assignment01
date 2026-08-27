import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/services/session_series.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-domain tests for finding a series inside the sessions a user
/// already has, and for deciding which of its occurrences can still be
/// called off.
void main() {
  const series = SessionSeries();

  Session session({
    required String id,
    String? seriesId,
    int day = 1,
    SessionStatus status = SessionStatus.confirmed,
  }) {
    return Session(
      id: id,
      requesterId: 'elder-1',
      volunteerId: 'volunteer-1',
      scheduledAt: DateTime(2026, 9, day, 10, 0),
      durationMinutes: 60,
      status: status,
      location: 'Community centre',
      isRecurring: seriesId != null,
      seriesId: seriesId,
    );
  }

  group('occurrencesOf', () {
    test('keeps only the sessions carrying the series id', () {
      final mine = session(id: 'a', seriesId: 'series-1', day: 1);
      final other = session(id: 'b', seriesId: 'series-2', day: 2);
      final oneOff = session(id: 'c', day: 3);

      expect(
        series.occurrencesOf(seriesId: 'series-1', sessions: [mine, other, oneOff]),
        [mine],
      );
    });

    test('sorts occurrences chronologically regardless of input order', () {
      final first = session(id: 'a', seriesId: 'series-1', day: 1);
      final second = session(id: 'b', seriesId: 'series-1', day: 8);
      final third = session(id: 'c', seriesId: 'series-1', day: 15);

      expect(
        series
            .occurrencesOf(seriesId: 'series-1', sessions: [third, first, second])
            .map((s) => s.id)
            .toList(),
        ['a', 'b', 'c'],
      );
    });

    test('never sweeps up one-off sessions, which carry a null seriesId', () {
      final oneOffs = [session(id: 'a'), session(id: 'b', day: 2)];

      expect(series.occurrencesOf(seriesId: '', sessions: oneOffs), isEmpty);
    });

    test('returns empty for a series id nothing matches', () {
      expect(
        series.occurrencesOf(
          seriesId: 'series-9',
          sessions: [session(id: 'a', seriesId: 'series-1')],
        ),
        isEmpty,
      );
    });

    test('returns empty for an empty session list', () {
      expect(series.occurrencesOf(seriesId: 'series-1', sessions: const []), isEmpty);
    });
  });

  group('cancellableOccurrences', () {
    test('keeps requested and confirmed sessions', () {
      final requested = session(id: 'a', status: SessionStatus.requested);
      final confirmed = session(id: 'b', day: 2, status: SessionStatus.confirmed);

      expect(
        series.cancellableOccurrences([requested, confirmed]).map((s) => s.id),
        ['a', 'b'],
      );
    });

    test('drops sessions that have already finished or been called off', () {
      final done = session(id: 'a', status: SessionStatus.completed);
      final gone = session(id: 'b', day: 2, status: SessionStatus.cancelled);

      expect(series.cancellableOccurrences([done, gone]), isEmpty);
    });

    test('matches the lifecycle rules rather than a second copy of them', () {
      for (final status in SessionStatus.values) {
        final occurrence = session(id: 'a', status: status);
        expect(
          series.cancellableOccurrences([occurrence]).isNotEmpty,
          status.canTransitionTo(SessionStatus.cancelled),
          reason: 'a ${status.name} session disagrees with the state machine',
        );
      }
    });

    test('sorts what it keeps chronologically', () {
      final later = session(id: 'a', day: 15, status: SessionStatus.confirmed);
      final sooner = session(id: 'b', day: 1, status: SessionStatus.requested);

      expect(
        series.cancellableOccurrences([later, sooner]).map((s) => s.id),
        ['b', 'a'],
      );
    });
  });

  group('hasCancellableOccurrences', () {
    test('true when at least one occurrence is still open', () {
      expect(
        series.hasCancellableOccurrences([
          session(id: 'a', status: SessionStatus.completed),
          session(id: 'b', day: 2, status: SessionStatus.confirmed),
        ]),
        isTrue,
      );
    });

    test('false for a finished series and for an empty list', () {
      expect(
        series.hasCancellableOccurrences([
          session(id: 'a', status: SessionStatus.completed),
          session(id: 'b', day: 2, status: SessionStatus.cancelled),
        ]),
        isFalse,
      );
      expect(series.hasCancellableOccurrences(const []), isFalse);
    });
  });
}
