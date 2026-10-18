import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/referrals/data/datasources/referrals_remote_data_source.dart';
import 'package:elderly_companion/features/referrals/domain/entities/referral.dart';
import 'package:elderly_companion/features/referrals/domain/entities/referral_code.dart';
import 'package:elderly_companion/features/referrals/domain/repositories/referral_repository.dart';

/// Satisfies [ReferralRepository] by delegating to [_dataSource] and
/// mapping data-layer exceptions to [Failure]s.
class ReferralRepositoryImpl implements ReferralRepository {
  const ReferralRepositoryImpl(this._dataSource);

  final ReferralsRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, ReferralCode>> getOrCreateMyCode(String userId) async {
    try {
      final dto = await _dataSource.getOrCreateCode(userId);
      return Right(dto.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Referral>> redeemCode({
    required String code,
    required String referredUserId,
    required String referredName,
  }) async {
    try {
      final dto = await _dataSource.redeemCode(
        code: code,
        referredUserId: referredUserId,
        referredName: referredName,
      );
      return Right(dto.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> hasRedeemedCode(String userId) async {
    try {
      final result = await _dataSource.hasRedeemedCode(userId);
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<List<Referral>> watchMyReferrals(String referrerId) {
    return _dataSource
        .watchMyReferrals(referrerId)
        .map((dtos) => dtos.map((dto) => dto.toEntity()).toList());
  }
}
