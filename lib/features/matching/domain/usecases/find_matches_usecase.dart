import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';
import 'package:elderly_companion/features/matching/domain/repositories/matching_repository.dart';
import 'package:elderly_companion/features/matching/domain/strategies/matching_strategy.dart';

/// Single business rule: find and rank candidate matches for the given
/// [MatchCriteria]. Ranking itself is delegated to [MatchingStrategy]
/// (Open/Closed — see domain/strategies/matching_strategy.dart); fetching
/// the raw candidate pool is delegated to [MatchingRepository] and is
/// still a stub pending the data layer.
class FindMatchesUseCase {
  const FindMatchesUseCase(
    this._repository, [
    this._strategy = const DefaultMatchingStrategy(),
  ]);

  final MatchingRepository _repository;
  final MatchingStrategy _strategy;

  Future<Either<Failure, List<MatchCandidate>>> call(MatchCriteria criteria) async {
    final result = await _repository.findMatches(criteria);
    return result.map((candidates) {
      final scored = candidates
          .map((c) => c.copyWith(matchScore: _strategy.score(c, criteria)))
          .toList()
        ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return scored;
    });
  }
}
