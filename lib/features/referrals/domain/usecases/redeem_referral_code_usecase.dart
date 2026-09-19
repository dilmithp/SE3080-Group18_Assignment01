import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/referrals/domain/entities/referral.dart';
import 'package:elderly_companion/features/referrals/domain/repositories/referral_repository.dart';

/// Single business rule: redeem a referral code on behalf of the signed-in
/// user, linking them to whoever shared that code.
class RedeemReferralCodeUseCase {
  const RedeemReferralCodeUseCase(this._repository);

  final ReferralRepository _repository;

  Future<Either<Failure, Referral>> call({
    required String code,
    required String referredUserId,
    required String referredName,
  }) {
    return _repository.redeemCode(
      code: code,
      referredUserId: referredUserId,
      referredName: referredName,
    );
  }
}
