import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/data/datasources/scheduling_remote_data_source.dart';
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
  }) async {
    try {
      final dto = await _dataSource.bookSession(
        requesterId: requesterId,
        volunteerId: volunteerId,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        location: location,
        notes: notes,
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
