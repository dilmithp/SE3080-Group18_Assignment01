import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/data/datasources/auth_trust_remote_data_source.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/verification_request.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/verification_repository.dart';

/// Satisfies [VerificationRepository]. Every method is stubbed — see
/// AuthRepositoryImpl for the pattern to follow when implementing.
class VerificationRepositoryImpl implements VerificationRepository {
  const VerificationRepositoryImpl(this._dataSource);

  final AuthTrustRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, VerificationRequest>> submitVerificationRequest({
    required String userId,
    required String documentUrl,
  }) async {
    try {
      final dto = await _dataSource.submitVerificationRequest(
        userId: userId,
        documentUrl: documentUrl,
      );
      return Right(dto.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<VerificationRequest?> watchVerificationStatus(String userId) {
    return _dataSource
        .watchVerificationStatus(userId)
        .map((dto) => dto?.toEntity());
  }

  @override
  Future<Either<Failure, VerificationRequest>> reviewVerificationRequest({
    required String requestId,
    required String reviewerId,
    required bool approve,
  }) async {
    try {
      final dto = await _dataSource.reviewVerificationRequest(
        requestId: requestId,
        reviewerId: reviewerId,
        approve: approve,
      );
      return Right(dto.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
