import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/verification_request.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/verification_repository.dart';

/// Single business rule: an admin approves or rejects a pending
/// verification request.
class ReviewVerificationRequestUseCase {
  const ReviewVerificationRequestUseCase(this._repository);

  final VerificationRepository _repository;

  Future<Either<Failure, VerificationRequest>> call({
    required String requestId,
    required String reviewerId,
    required bool approve,
  }) async {
    return _repository.reviewVerificationRequest(
      requestId: requestId,
      reviewerId: reviewerId,
      approve: approve,
    );
  }
}
