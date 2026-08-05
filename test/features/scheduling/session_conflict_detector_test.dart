import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/services/session_conflict_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-domain tests — no repository, no mocks, no Firebase. The overlap
/// maths and the "who counts as busy" rule are asserted here so the
/// Firestore transaction that calls this in a later chunk only has to be
/// tested for its transaction behaviour, not its arithmetic.
void main() {
  const detector = SessionConflictDetector();

  Session session({
    String id = 'candidate',
    String requesterId = 'elder-1',
    String volunteerId = 'volunteer-1',
    DateTime? scheduledAt,
    int durationMinutes = 60,
    SessionStatus status = SessionStatus.confirmed,
  }) {
    return Session(
      id: id,
      requesterId: requesterId,
      volunteerId: volunteerId,
      scheduledAt: scheduledAt ?? DateTime(2026, 9, 1, 10, 0),
      durationMinutes: durationMinutes,
      status: status,
      location: 'Community centre',
    );
  }

  group('overlaps', () {
    test('detects a partial overlap in either direction', () {
      final a = session(scheduledAt: DateTime(2026, 9, 1, 10, 0));
      final b = session(id: 'b', scheduledAt: DateTime(2026, 9, 1, 10, 30));

      expect(detector.overlaps(a, b), isTrue);
      expect(detector.overlaps(b, a), isTrue);
    });

    test('detects a session fully contained in another', () {
      final long = session(scheduledAt: DateTime(2026, 9, 1, 10, 0), durationMinutes: 180);
      final short = session(
        id: 'b',
        scheduledAt: DateTime(2026, 9, 1, 11, 0),
        durationMinutes: 30,
      );

      expect(detector.overlaps(long, short), isTrue);
      expect(detector.overlaps(short, long), isTrue);
    });

    test('back-to-back sessions do not overlap — intervals are half-open', () {
      final first = session(scheduledAt: DateTime(2026, 9, 1, 10, 0), durationMinutes: 60);
      final second = session(id: 'b', scheduledAt: DateTime(2026, 9, 1, 11, 0));

      expect(detector.overlaps(first, second), isFalse);
      expect(detector.overlaps(second, first), isFalse);
    });

    test('a one-minute gap does not overlap', () {
      final first = session(scheduledAt: DateTime(2026, 9, 1, 10, 0), durationMinutes: 60);
      final second = session(id: 'b', scheduledAt: DateTime(2026, 9, 1, 11, 1));

      expect(detector.overlaps(first, second), isFalse);
    });

    test('sessions on different days do not overlap', () {
      final today = session(scheduledAt: DateTime(2026, 9, 1, 10, 0));
      final tomorrow = session(id: 'b', scheduledAt: DateTime(2026, 9, 2, 10, 0));

      expect(detector.overlaps(today, tomorrow), isFalse);
    });

    test('a non-positive duration overlaps nothing', () {
      final zero = session(durationMinutes: 0);
      final negative = session(id: 'b', durationMinutes: -30);
      final normal = session(id: 'c');

      expect(detector.overlaps(zero, normal), isFalse);
      expect(detector.overlaps(normal, zero), isFalse);
      expect(detector.overlaps(negative, normal), isFalse);
    });

    test('endOf is start plus duration', () {
      final s = session(scheduledAt: DateTime(2026, 9, 1, 10, 0), durationMinutes: 90);

      expect(detector.endOf(s), DateTime(2026, 9, 1, 11, 30));
    });
  });

  group('sharesParticipant', () {
    test('true when the same person is the requester on both', () {
      final a = session(requesterId: 'elder-1', volunteerId: 'volunteer-1');
      final b = session(id: 'b', requesterId: 'elder-1', volunteerId: 'volunteer-2');

      expect(detector.sharesParticipant(a, b), isTrue);
    });

    test('true when a person requests one session and volunteers on another', () {
      final a = session(requesterId: 'elder-1', volunteerId: 'volunteer-1');
      final b = session(id: 'b', requesterId: 'elder-2', volunteerId: 'elder-1');

      expect(detector.sharesParticipant(a, b), isTrue);
    });

    test('false when the two sessions involve four different people', () {
      final a = session(requesterId: 'elder-1', volunteerId: 'volunteer-1');
      final b = session(id: 'b', requesterId: 'elder-2', volunteerId: 'volunteer-2');

      expect(detector.sharesParticipant(a, b), isFalse);
    });
  });

  group('conflictsFor', () {
    test('returns an overlapping confirmed session for a shared participant', () {
      final candidate = session(id: 'candidate', status: SessionStatus.requested);
      final clash = session(id: 'existing', scheduledAt: DateTime(2026, 9, 1, 10, 30));

      final conflicts = detector.conflictsFor(
        candidate: candidate,
        existing: [clash],
      );

      expect(conflicts, [clash]);
      expect(detector.hasConflict(candidate: candidate, existing: [clash]), isTrue);
    });

    test('ignores the stored copy of the candidate itself', () {
      final candidate = session(id: 'candidate', status: SessionStatus.requested);
      final storedCopy = session(id: 'candidate');

      expect(
        detector.conflictsFor(candidate: candidate, existing: [storedCopy]),
        isEmpty,
      );
    });

    test('ignores sessions between other people at the same time', () {
      final candidate = session(id: 'candidate', status: SessionStatus.requested);
      final unrelated = session(
        id: 'other',
        requesterId: 'elder-9',
        volunteerId: 'volunteer-9',
      );

      expect(
        detector.conflictsFor(candidate: candidate, existing: [unrelated]),
        isEmpty,
      );
    });

    test('ignores completed and cancelled sessions — they hold no slot', () {
      final candidate = session(id: 'candidate', status: SessionStatus.requested);
      final settled = [
        session(id: 'done', status: SessionStatus.completed),
        session(id: 'dropped', status: SessionStatus.cancelled),
      ];

      expect(
        detector.conflictsFor(candidate: candidate, existing: settled),
        isEmpty,
      );
    });

    test('ignores other pending requests by default — only acceptance takes '
        'the slot', () {
      final candidate = session(id: 'candidate', status: SessionStatus.requested);
      final alsoPending = session(id: 'pending', status: SessionStatus.requested);

      expect(
        detector.conflictsFor(candidate: candidate, existing: [alsoPending]),
        isEmpty,
      );
    });

    test('treats pending requests as blocking when configured to', () {
      const strict = SessionConflictDetector(
        blockingStatuses: {SessionStatus.requested, SessionStatus.confirmed},
      );
      final candidate = session(id: 'candidate', status: SessionStatus.requested);
      final alsoPending = session(id: 'pending', status: SessionStatus.requested);

      expect(
        strict.conflictsFor(candidate: candidate, existing: [alsoPending]),
        [alsoPending],
      );
    });

    test('returns every clash, not just the first', () {
      final candidate = session(
        id: 'candidate',
        scheduledAt: DateTime(2026, 9, 1, 10, 0),
        durationMinutes: 180,
        status: SessionStatus.requested,
      );
      final first = session(id: 'first', scheduledAt: DateTime(2026, 9, 1, 10, 30));
      final second = session(id: 'second', scheduledAt: DateTime(2026, 9, 1, 12, 30));
      final clear = session(id: 'clear', scheduledAt: DateTime(2026, 9, 1, 15, 0));

      final conflicts = detector.conflictsFor(
        candidate: candidate,
        existing: [first, clear, second],
      );

      expect(conflicts, [first, second]);
    });

    test('an empty schedule never conflicts', () {
      expect(
        detector.hasConflict(candidate: session(), existing: const []),
        isFalse,
      );
    });
  });
}
