import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/verification_request.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/verification_repository.dart';

/// Single business rule: submit an identity document for review.
class SubmitVerificationRequestUseCase {
  const SubmitVerificationRequestUseCase(this._repository);

  final VerificationRepository _repository;

  Future<Either<Failure, VerificationRequest>> call({
    required String userId,
    required String documentUrl,
  }) async {
    throw UnimplementedError(
      'TODO(Pathirana): implement via ${_repository.runtimeType}',
    );
  }
}
