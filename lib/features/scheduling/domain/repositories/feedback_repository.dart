import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_feedback.dart';

/// Contract: rating/feedback submission and reads only. Split from
/// [SessionRepository] (Interface Segregation) — a screen that only submits
/// feedback must not be forced to depend on session-booking methods.
///
/// Owner: Ranketh (features/scheduling).
abstract class FeedbackRepository {
  Future<Either<Failure, SessionFeedback>> submitFeedback({
    required String sessionId,
    required String raterId,
    required int rating,
    String? comment,
  });

  Future<Either<Failure, List<SessionFeedback>>> getFeedbackForSession(
    String sessionId,
  );
}
