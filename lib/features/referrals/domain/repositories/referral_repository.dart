import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/referrals/domain/entities/referral.dart';
import 'package:elderly_companion/features/referrals/domain/entities/referral_code.dart';

/// Abstract interface for the referral program — presentation and domain
/// depend only on this; `data/repositories/referral_repository_impl.dart`
/// is the only implementation.
///
/// Owner: referrals (new, unassigned in the original team split, same as
/// `community` — see the ownership note in docs/DATA_MODEL.md).
abstract class ReferralRepository {
  /// Returns [userId]'s existing referral code, generating and persisting a
  /// fresh one on first call.
  Future<Either<Failure, ReferralCode>> getOrCreateMyCode(String userId);

  /// Redeems [code] on behalf of [referredUserId]. Fails with
  /// [PermissionFailure] if [referredUserId] is the code's own owner, or has
  /// already redeemed a code before; fails with [NotFoundFailure] if [code]
  /// does not exist.
  Future<Either<Failure, Referral>> redeemCode({
    required String code,
    required String referredUserId,
    required String referredName,
  });

  /// Whether [userId] has already redeemed a referral code. Used to decide
  /// whether to show the "have a code?" form at all.
  Future<Either<Failure, bool>> hasRedeemedCode(String userId);

  /// Everyone [referrerId] has successfully referred, newest first.
  Stream<List<Referral>> watchMyReferrals(String referrerId);
}
