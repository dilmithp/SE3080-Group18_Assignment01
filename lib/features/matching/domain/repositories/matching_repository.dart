import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';

/// Contract: locate and rank candidate matches for a given set of criteria.
///
/// Owner: Wijekoon (features/matching).
abstract class MatchingRepository {
  Future<Either<Failure, List<MatchCandidate>>> findMatches(
    MatchCriteria criteria,
  );
}
