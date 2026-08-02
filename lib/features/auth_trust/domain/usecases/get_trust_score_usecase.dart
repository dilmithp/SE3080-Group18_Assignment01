import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/trust_score.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/trust_score_repository.dart';

/// Single business rule: fetch a user's current trust score.
class GetTrustScoreUseCase {
  const GetTrustScoreUseCase(this._repository);

  final TrustScoreRepository _repository;

  Future<Either<Failure, TrustScore>> call(String userId) async {
    throw UnimplementedError(
      'TODO(Pathirana): implement via ${_repository.runtimeType}',
    );
  }
}
