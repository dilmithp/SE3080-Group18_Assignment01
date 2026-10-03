import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';
import 'package:elderly_companion/features/scheduling/domain/services/session_attendance_rules.dart';

/// Single business rule: a participant may check in or out only when
/// [SessionAttendanceRules] allows it. The session is read first so the
/// rules run on the stored state, not on what the screen last showed.
class RecordAttendanceUseCase {
  const RecordAttendanceUseCase(this._repository);

  final SessionRepository _repository;

  Future<Either<Failure, Session>> call({
    required String sessionId,
    required bool checkOut,
    required DateTime now,
  }) async {
    final loaded = await _repository.getSession(sessionId);
    return loaded.fold<Future<Either<Failure, Session>>>(
      (failure) async => Left<Failure, Session>(failure),
      (session) async {
        final allowed = checkOut
            ? SessionAttendanceRules.canCheckOut(session)
            : SessionAttendanceRules.canCheckIn(session, now);
        if (!allowed) {
          return Left<Failure, Session>(
            UnknownFailure(
              checkOut
                  ? 'You can check out after you have checked in.'
                  : 'Check-in opens 30 minutes before the visit and closes when it ends.',
            ),
          );
        }
        return _repository.recordAttendance(sessionId: sessionId, checkOut: checkOut);
      },
    );
  }
}
