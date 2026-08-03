import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/data/datasources/scheduling_remote_data_source.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_feedback.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/feedback_repository.dart';

/// Satisfies [FeedbackRepository]. Every method is stubbed — see
/// SessionRepositoryImpl for the pattern to follow when implementing.
class FeedbackRepositoryImpl implements FeedbackRepository {
  const FeedbackRepositoryImpl(this._dataSource);

  final SchedulingRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, SessionFeedback>> submitFeedback({
    required String sessionId,
    required String raterId,
    required int rating,
    String? comment,
  }) async {
    try {
      final dto = await _dataSource.submitFeedback(
        sessionId: sessionId,
        raterId: raterId,
        rating: rating,
        comment: comment,
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
  Future<Either<Failure, List<SessionFeedback>>> getFeedbackForSession(
    String sessionId,
  ) async {
    try {
      final dtos = await _dataSource.getFeedbackForSession(sessionId);
      return Right(dtos.map((d) => d.toEntity()).toList());
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
}
