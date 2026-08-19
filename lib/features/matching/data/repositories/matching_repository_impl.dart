import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
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
    try {
      final dtos = await _dataSource.findMatches(
        locality: criteria.locality,
        radiusKm: criteria.radiusKm,
        requiredSkills: criteria.requiredSkills,
        preferredTimes: criteria.preferredTimes,
      );
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
