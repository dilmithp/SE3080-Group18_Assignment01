import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';

/// Single business rule: accept a requested session.
///
/// Deliberately separate from [UpdateSessionStatusUseCase] rather than a
/// branch inside it — confirming is the one transition that has to re-check
/// the slot at accept time, and the repository fulfils it with a
/// transaction instead of a plain status write.
class ConfirmSessionUseCase {
  const ConfirmSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<Either<Failure, Session>> call({
    required String sessionId,
    required String confirmingUserId,
  }) async {
    return _repository.confirmSession(
      sessionId: sessionId,
      confirmingUserId: confirmingUserId,
    );
  }
}
