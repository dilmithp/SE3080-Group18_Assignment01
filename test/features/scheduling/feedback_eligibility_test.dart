import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_feedback.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/services/feedback_eligibility.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-domain tests. The two screens that offer the feedback form both ask
/// this rule, so every reason a rating can be refused is pinned here rather
/// than in widget code.
void main() {
  const eligibility = FeedbackEligibility();

  Session session({SessionStatus status = SessionStatus.completed}) => Session(
        id: 'session-1',
        requesterId: 'elder-1',
        volunteerId: 'volunteer-1',
        scheduledAt: DateTime(2026, 9, 1, 10, 0),
        durationMinutes: 60,
        status: status,
        location: 'Community centre',
      );

  SessionFeedback feedback({String raterId = 'elder-1'}) => SessionFeedback(
        sessionId: 'session-1',
        raterId: raterId,
        rating: 5,
        createdAt: DateTime(2026, 9, 1, 11, 30),
      );

  group('canLeaveFeedback', () {
    test('a participant may rate a completed session nobody has rated', () {
      expect(
        eligibility.canLeaveFeedback(
          session: session(),
          userId: 'elder-1',
          existingFeedback: const [],
        ),
        isTrue,
      );
    });

    test('either participant may rate — requester and volunteer alike', () {
      for (final userId in ['elder-1', 'volunteer-1']) {
        expect(
          eligibility.canLeaveFeedback(
            session: session(),
            userId: userId,
            existingFeedback: const [],
          ),
          isTrue,
          reason: '$userId should be able to rate their own session',
        );
      }
    });

    test('refused while nobody is signed in', () {
      expect(
        eligibility.canLeaveFeedback(
          session: session(),
          userId: null,
          existingFeedback: const [],
        ),
        isFalse,
      );
    });

    test('refused for every status except completed', () {
      for (final status in SessionStatus.values) {
        expect(
          eligibility.canLeaveFeedback(
            session: session(status: status),
            userId: 'elder-1',
            existingFeedback: const [],
          ),
          status == SessionStatus.completed,
          reason: 'a ${status.name} session should '
              '${status == SessionStatus.completed ? 'allow' : 'refuse'} feedback',
        );
      }
    });

    test('refused for somebody who was not on the session', () {
      expect(
        eligibility.canLeaveFeedback(
          session: session(),
          userId: 'stranger-1',
          existingFeedback: const [],
        ),
        isFalse,
      );
    });

    test('refused once this user has already rated — feedback is write-once', () {
      expect(
        eligibility.canLeaveFeedback(
          session: session(),
          userId: 'elder-1',
          existingFeedback: [feedback(raterId: 'elder-1')],
        ),
        isFalse,
      );
    });

    test('the other participant may still rate after the first one has', () {
      expect(
        eligibility.canLeaveFeedback(
          session: session(),
          userId: 'volunteer-1',
          existingFeedback: [feedback(raterId: 'elder-1')],
        ),
        isTrue,
      );
    });
  });

  group('isParticipant', () {
    test('true for the requester and the volunteer, false for anyone else', () {
      expect(eligibility.isParticipant(session: session(), userId: 'elder-1'), isTrue);
      expect(
        eligibility.isParticipant(session: session(), userId: 'volunteer-1'),
        isTrue,
      );
      expect(
        eligibility.isParticipant(session: session(), userId: 'stranger-1'),
        isFalse,
      );
    });
  });

  group('hasRated', () {
    test('false against an empty list', () {
      expect(
        eligibility.hasRated(userId: 'elder-1', existingFeedback: const []),
        isFalse,
      );
    });

    test('matches on raterId only, ignoring ratings left by anyone else', () {
      expect(
        eligibility.hasRated(
          userId: 'elder-1',
          existingFeedback: [feedback(raterId: 'volunteer-1')],
        ),
        isFalse,
      );
      expect(
        eligibility.hasRated(
          userId: 'elder-1',
          existingFeedback: [
            feedback(raterId: 'volunteer-1'),
            feedback(raterId: 'elder-1'),
          ],
        ),
        isTrue,
      );
    });
  });
}
