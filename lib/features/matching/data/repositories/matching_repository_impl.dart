import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/matching/data/datasources/matching_remote_data_source.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';
import 'package:elderly_companion/features/matching/domain/repositories/matching_repository.dart';

/// Satisfies [MatchingRepository]. The job of implementing this class is to
/// call [_dataSource], catch the exceptions in core/error/exceptions.dart,
/// and map them to a [Failure].
class MatchingRepositoryImpl implements MatchingRepository {
  const MatchingRepositoryImpl(this._dataSource);

  final MatchingRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, List<MatchCandidate>>> findMatches(
    MatchCriteria criteria,
  ) async {
    throw UnimplementedError('TODO(Wijekoon): implement via $_dataSource');
  }
}
