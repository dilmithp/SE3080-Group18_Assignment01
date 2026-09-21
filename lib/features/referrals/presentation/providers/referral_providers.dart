import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/features/referrals/data/datasources/referrals_remote_data_source.dart';
import 'package:elderly_companion/features/referrals/data/repositories/referral_repository_impl.dart';
import 'package:elderly_companion/features/referrals/domain/entities/referral.dart';
import 'package:elderly_companion/features/referrals/domain/entities/referral_code.dart';
import 'package:elderly_companion/features/referrals/domain/repositories/referral_repository.dart';
import 'package:elderly_companion/features/referrals/domain/usecases/get_or_create_referral_code_usecase.dart';
import 'package:elderly_companion/features/referrals/domain/usecases/redeem_referral_code_usecase.dart';

/// All Dependency-Inversion wiring for referrals lives here: presentation
/// and domain depend only on the abstract [ReferralRepository] interface;
/// this file is the only place that knows [ReferralRepositoryImpl] etc.
/// exist.

final referralsRemoteDataSourceProvider = Provider<ReferralsRemoteDataSource>((ref) {
  return FirebaseReferralsRemoteDataSource(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepositoryImpl(ref.watch(referralsRemoteDataSourceProvider));
});

final getOrCreateReferralCodeUseCaseProvider =
    Provider<GetOrCreateReferralCodeUseCase>((ref) {
  return GetOrCreateReferralCodeUseCase(ref.watch(referralRepositoryProvider));
});

final redeemReferralCodeUseCaseProvider = Provider<RedeemReferralCodeUseCase>((ref) {
  return RedeemReferralCodeUseCase(ref.watch(referralRepositoryProvider));
});

/// The signed-in user's referral code, generating one on first access.
/// Throws the [Failure] on error so it surfaces through [AsyncValue.error]
/// the same way the stream-backed providers do.
final myReferralCodeProvider = FutureProvider.family<ReferralCode, String>((ref, userId) async {
  final result = await ref.watch(getOrCreateReferralCodeUseCaseProvider).call(userId);
  return result.fold((failure) => throw failure, (code) => code);
});

/// Whether [userId] has already redeemed someone else's referral code.
final hasRedeemedCodeProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final result = await ref.watch(referralRepositoryProvider).hasRedeemedCode(userId);
  return result.fold((failure) => throw failure, (hasRedeemed) => hasRedeemed);
});

/// Live list of everyone [referrerId] has referred, newest first.
final myReferralsProvider = StreamProvider.family<List<Referral>, String>((ref, referrerId) {
  return ref.watch(referralRepositoryProvider).watchMyReferrals(referrerId);
});
