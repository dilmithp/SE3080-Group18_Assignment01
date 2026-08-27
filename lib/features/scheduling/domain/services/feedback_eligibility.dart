import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_feedback.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';

/// Decides whether a given person may still rate a given session.
///
/// Pure Dart and side-effect free, for the same reason
/// [SessionConflictDetector] is: the rule is worth testing on its own, and
/// the screen that offers the "Leave feedback" action should not be the
/// place it lives.
///
/// Feedback is write-once by design — `firestore.rules` denies both update
/// and delete on `session_feedback` — so "already rated" is permanent, and
/// offering the form again would only produce a second document that
/// nobody can reconcile.
///
/// Owner: Ranketh (features/scheduling).
class FeedbackEligibility {
  const FeedbackEligibility();

  /// Whether [userId] may leave feedback on [session] given the
  /// [existingFeedback] already recorded against it.
  ///
  /// [userId] is nullable so callers can pass an unresolved auth state
  /// straight through: nobody signed in means nobody to attribute a rating
  /// to, which is a "no" rather than a special case at the call site.
  bool canLeaveFeedback({
    required Session session,
    required String? userId,
    required Iterable<SessionFeedback> existingFeedback,
  }) {
    if (userId == null) return false;
    if (session.status != SessionStatus.completed) return false;
    if (!isParticipant(session: session, userId: userId)) return false;
    return !hasRated(userId: userId, existingFeedback: existingFeedback);
  }

  /// Whether [userId] is the requester or the volunteer on [session].
  /// Mirrors the participant check in `firestore.rules` — a non-participant
  /// would be refused by the rules anyway, so there is no point offering
  /// them the form.
  bool isParticipant({required Session session, required String userId}) =>
      userId == session.requesterId || userId == session.volunteerId;

  /// Whether [userId] has already rated, according to [existingFeedback].
  bool hasRated({
    required String userId,
    required Iterable<SessionFeedback> existingFeedback,
  }) =>
      existingFeedback.any((feedback) => feedback.raterId == userId);
}
