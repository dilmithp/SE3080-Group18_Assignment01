import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-domain tests — no repository, no mocks, no Firebase. The booking
/// lifecycle is the one rule every other scheduling chunk leans on, so the
/// whole transition matrix is asserted explicitly rather than sampled.
void main() {
  group('SessionStatus.canTransitionTo', () {
    test('requested may be confirmed or cancelled', () {
      expect(SessionStatus.requested.canTransitionTo(SessionStatus.confirmed), isTrue);
      expect(SessionStatus.requested.canTransitionTo(SessionStatus.cancelled), isTrue);
    });

    test('requested may not skip straight to completed', () {
      expect(SessionStatus.requested.canTransitionTo(SessionStatus.completed), isFalse);
    });

    test('confirmed may be completed or cancelled', () {
      expect(SessionStatus.confirmed.canTransitionTo(SessionStatus.completed), isTrue);
      expect(SessionStatus.confirmed.canTransitionTo(SessionStatus.cancelled), isTrue);
    });

    test('confirmed may not fall back to requested', () {
      expect(SessionStatus.confirmed.canTransitionTo(SessionStatus.requested), isFalse);
    });

    test('completed is terminal — no edge out of it', () {
      for (final next in SessionStatus.values) {
        expect(
          SessionStatus.completed.canTransitionTo(next),
          isFalse,
          reason: 'completed -> ${next.name} must be rejected',
        );
      }
    });

    test('cancelled is terminal — a cancelled session is rebooked, not revived', () {
      for (final next in SessionStatus.values) {
        expect(
          SessionStatus.cancelled.canTransitionTo(next),
          isFalse,
          reason: 'cancelled -> ${next.name} must be rejected',
        );
      }
    });

    test('re-applying the current status is never a legal transition', () {
      for (final status in SessionStatus.values) {
        expect(
          status.canTransitionTo(status),
          isFalse,
          reason: '${status.name} -> ${status.name} must be rejected',
        );
      }
    });
  });

  group('SessionStatus.isTerminal', () {
    test('open states are not terminal', () {
      expect(SessionStatus.requested.isTerminal, isFalse);
      expect(SessionStatus.confirmed.isTerminal, isFalse);
    });

    test('settled states are terminal', () {
      expect(SessionStatus.completed.isTerminal, isTrue);
      expect(SessionStatus.cancelled.isTerminal, isTrue);
    });
  });

  group('SessionStatus.allowedNextStatuses', () {
    test('every status has an entry, so no lookup can blow up', () {
      for (final status in SessionStatus.values) {
        expect(() => status.allowedNextStatuses, returnsNormally);
      }
    });

    test('exposes exactly the edges canTransitionTo accepts', () {
      for (final status in SessionStatus.values) {
        for (final next in SessionStatus.values) {
          expect(
            status.canTransitionTo(next),
            status.allowedNextStatuses.contains(next),
            reason: '${status.name} -> ${next.name} disagrees between the two',
          );
        }
      }
    });
  });

  group('SessionStatus.label', () {
    test('every status has a human-readable label', () {
      expect(SessionStatus.requested.label, 'Requested');
      expect(SessionStatus.confirmed.label, 'Confirmed');
      expect(SessionStatus.completed.label, 'Completed');
      expect(SessionStatus.cancelled.label, 'Cancelled');
    });
  });
}
