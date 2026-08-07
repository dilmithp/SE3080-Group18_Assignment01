import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';

/// Contract: session-booking lifecycle only — booking, status transitions
/// and reads. Split from [FeedbackRepository] (Interface Segregation) — a
/// screen that only submits feedback must not be forced to depend on
/// session-booking methods.
///
/// Owner: Ranketh (features/scheduling).
abstract class SessionRepository {
  Future<Either<Failure, Session>> bookSession({
    required String requesterId,
    required String volunteerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String location,
    String? notes,
  });

  Future<Either<Failure, Session>> updateSessionStatus({
    required String sessionId,
    required SessionStatus status,
  });

  /// Accepts [sessionId] on behalf of [confirmingUserId] — the
  /// `requested -> confirmed` edge, which unlike a plain status write
  /// re-checks the slot at accept time so two overlapping requests cannot
  /// both be confirmed.
  ///
  /// Returns a [Failure] carrying a conflict message when the slot was
  /// taken in the meantime.
  Future<Either<Failure, Session>> confirmSession({
    required String sessionId,
    required String confirmingUserId,
  });

  Future<Either<Failure, Session>> getSession(String sessionId);

  /// Emits the current list of sessions involving [userId] (as requester or
  /// volunteer) on every change.
  Stream<List<Session>> watchSessionsForUser(String userId);
}
