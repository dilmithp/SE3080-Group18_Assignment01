import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/referrals/domain/entities/referral_code.dart';
import 'package:elderly_companion/features/referrals/domain/repositories/referral_repository.dart';

/// Single business rule: every user has exactly one referral code, created
/// the first time it's requested.
class GetOrCreateReferralCodeUseCase {
  const GetOrCreateReferralCodeUseCase(this._repository);

  final ReferralRepository _repository;

  Future<Either<Failure, ReferralCode>> call(String userId) {
    return _repository.getOrCreateMyCode(userId);
  }
}
