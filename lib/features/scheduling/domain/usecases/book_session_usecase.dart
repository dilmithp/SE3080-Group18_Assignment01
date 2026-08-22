import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';

/// Single business rule: book a new companionship/volunteering session.
class BookSessionUseCase {
  const BookSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<Either<Failure, Session>> call({
    required String requesterId,
    required String volunteerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String location,
    String? notes,
  }) async {
    return _repository.bookSession(
      requesterId: requesterId,
      volunteerId: volunteerId,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      location: location,
      notes: notes,
    );
  }
}
