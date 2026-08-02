import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/data/datasources/auth_trust_remote_data_source.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/trust_score.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/trust_score_repository.dart';

/// Satisfies [TrustScoreRepository]. Every method is stubbed — see
/// AuthRepositoryImpl for the pattern to follow when implementing.
class TrustScoreRepositoryImpl implements TrustScoreRepository {
  const TrustScoreRepositoryImpl(this._dataSource);

  final AuthTrustRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, TrustScore>> getTrustScore(String userId) async {
    throw UnimplementedError('TODO(Pathirana): implement via $_dataSource');
  }

  @override
  Stream<TrustScore?> watchTrustScore(String userId) {
    throw UnimplementedError('TODO(Pathirana): implement via $_dataSource');
  }
}
