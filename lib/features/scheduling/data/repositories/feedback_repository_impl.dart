import 'package:dartz/dartz.dart';

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
    throw UnimplementedError('TODO(Ranketh): implement via $_dataSource');
  }

  @override
  Future<Either<Failure, List<SessionFeedback>>> getFeedbackForSession(
    String sessionId,
  ) async {
    throw UnimplementedError('TODO(Ranketh): implement via $_dataSource');
  }
}
