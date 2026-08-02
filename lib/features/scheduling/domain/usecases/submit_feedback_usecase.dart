import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_feedback.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/feedback_repository.dart';

/// Single business rule: submit rating/feedback for a completed session.
class SubmitFeedbackUseCase {
  const SubmitFeedbackUseCase(this._repository);

  final FeedbackRepository _repository;

  Future<Either<Failure, SessionFeedback>> call({
    required String sessionId,
    required String raterId,
    required int rating,
    String? comment,
  }) async {
    throw UnimplementedError(
      'TODO(Ranketh): implement via ${_repository.runtimeType}',
    );
  }
}
