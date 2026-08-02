import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';

/// Single business rule: transition a session to a new [SessionStatus].
class UpdateSessionStatusUseCase {
  const UpdateSessionStatusUseCase(this._repository);

  final SessionRepository _repository;

  Future<Either<Failure, Session>> call({
    required String sessionId,
    required SessionStatus status,
  }) async {
    throw UnimplementedError(
      'TODO(Ranketh): implement via ${_repository.runtimeType}',
    );
  }
}
