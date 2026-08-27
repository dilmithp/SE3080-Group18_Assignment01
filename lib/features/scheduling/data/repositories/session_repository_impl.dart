import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/data/datasources/scheduling_remote_data_source.dart';
import 'package:elderly_companion/features/scheduling/data/exceptions/scheduling_exceptions.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';

/// Satisfies [SessionRepository]. Every method is stubbed — the job of
/// implementing this class is to call [_dataSource], catch the exceptions
/// in core/error/exceptions.dart, and map them to a [Failure].
class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._dataSource);

  final SchedulingRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, Session>> bookSession({
    required String requesterId,
    required String volunteerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String location,
    String? notes,
    bool isRecurring = false,
    String? recurrenceRule,
    String? seriesId,
  }) async {
    try {
      final dto = await _dataSource.bookSession(
        requesterId: requesterId,
        volunteerId: volunteerId,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        location: location,
        notes: notes,
        isRecurring: isRecurring,
        recurrenceRule: recurrenceRule,
        seriesId: seriesId,
      );
      return Right(dto.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Session>> updateSessionStatus({
    required String sessionId,
    required SessionStatus status,
  }) async {
    try {
      final dto = await _dataSource.updateSessionStatus(
        sessionId: sessionId,
        status: status,
      );
      return Right(dto.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Session>> confirmSession({
    required String sessionId,
    required String confirmingUserId,
  }) async {
    try {
      final dto = await _dataSource.confirmSession(
        sessionId: sessionId,
        confirmingUserId: confirmingUserId,
      );
      return Right(dto.toEntity());
    } on SessionConflictException catch (e) {
      // TODO(ranketh): a dedicated ConflictFailure belongs in
      // core/error/failures.dart so callers can branch on the type instead
      // of reading the message — Failure is sealed, so it cannot be
      // subclassed from this feature. Needs the two-reviewer process for
      // core changes.
      return Left(UnknownFailure(e.message));
    } on InvalidSessionTransitionException catch (e) {
      return Left(UnknownFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Session>> getSession(String sessionId) async {
    try {
      final dto = await _dataSource.getSession(sessionId);
      return Right(dto.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<List<Session>> watchSessionsForUser(String userId) {
    return _dataSource
        .watchSessionsForUser(userId)
        .map((dtos) => dtos.map((d) => d.toEntity()).toList());
  }
}
