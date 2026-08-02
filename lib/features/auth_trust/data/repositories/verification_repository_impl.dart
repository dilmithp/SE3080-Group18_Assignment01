import 'package:dartz/dartz.dart';

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
    throw UnimplementedError('TODO(Pathirana): implement via $_dataSource');
  }

  @override
  Stream<VerificationRequest?> watchVerificationStatus(String userId) {
    throw UnimplementedError('TODO(Pathirana): implement via $_dataSource');
  }

  @override
  Future<Either<Failure, VerificationRequest>> reviewVerificationRequest({
    required String requestId,
    required String reviewerId,
    required bool approve,
  }) async {
    throw UnimplementedError('TODO(Pathirana): implement via $_dataSource');
  }
}
