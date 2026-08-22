import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';
import 'package:elderly_companion/features/matching/domain/repositories/matching_repository.dart';
import 'package:elderly_companion/features/matching/domain/strategies/matching_strategy.dart';

/// Single business rule: find and rank candidate matches for the given
/// [MatchCriteria]. Ranking itself is delegated to whichever [MatchingStrategy]
/// [MatchCriteria.strategyType] names (Open/Closed — see
/// domain/strategies/matching_strategy.dart); fetching the raw candidate
/// pool is delegated to [MatchingRepository] and is still a stub pending
/// the data layer.
class FindMatchesUseCase {
  const FindMatchesUseCase(this._repository);

  final MatchingRepository _repository;

  Future<Either<Failure, List<MatchCandidate>>> call(MatchCriteria criteria) async {
    final strategy = criteria.strategyType.toStrategy();
    final result = await _repository.findMatches(criteria);
    return result.map((candidates) {
      final scored = candidates.map((c) {
        final withScore = c.copyWith(matchScore: strategy.score(c, criteria));
        return withScore.copyWith(
          matchReasons: _explain(withScore, criteria),
        );
      }).toList()
        ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return scored;
    });
  }

  /// Human-readable reasons behind a candidate's rank, surfaced to the
  /// user alongside the match score. Deliberately kept separate from
  /// [MatchingStrategy.score] — the strategy stays a pure scoring
  /// function; explaining *why* a score came out the way it did is a
  /// presentation-facing concern layered on top, not a new heuristic, so
  /// it doesn't belong behind the Open/Closed strategy interface.
  ///
  /// Which reason *leads* the list tracks [MatchCriteria.strategyType]:
  /// candidate cards show only `matchReasons.first` (see
  /// MatchingScreen/MatchDetailsScreen), so under
  /// [MatchingStrategyType.nearest] that should be the distance reason,
  /// under [MatchingStrategyType.mostTrusted] the trust reason, and so on
  /// — otherwise a card could headline "Highly trusted" for a search the
  /// user explicitly asked to rank by distance.
  List<String> _explain(MatchCandidate candidate, MatchCriteria criteria) {
    final proximityReason = criteria.origin != null
        ? '${candidate.distanceKm.toStringAsFixed(1)} km away'
        : candidate.profile.locality.isNotEmpty
            ? 'In ${candidate.profile.locality}'
            : null;

    final matchedSkills = criteria.requiredSkills
        .where((skill) => candidate.profile.skillsOffered.contains(skill))
        .toList();
    final skillReason =
        matchedSkills.isEmpty ? null : 'Offers ${matchedSkills.join(', ')}';

    final trustReason = candidate.trustScore >= 0.7
        ? 'Highly trusted (${(candidate.trustScore.clamp(0.0, 1.0) * 100).round()}% trust score)'
        : null;

    String? availabilityReason;
    if (criteria.preferredTimes.isNotEmpty) {
      final availableDays =
          candidate.profile.availabilityWindows.map((w) => w.dayOfWeek).toSet();
      final matchedDays =
          criteria.preferredTimes.where(availableDays.contains).toList();
      if (matchedDays.isNotEmpty) {
        availabilityReason = 'Available ${matchedDays.join(', ')}';
      }
    }

    final ordered = switch (criteria.strategyType) {
      MatchingStrategyType.nearest => [
          proximityReason,
          trustReason,
          skillReason,
          availabilityReason,
        ],
      MatchingStrategyType.mostTrusted => [
          trustReason,
          proximityReason,
          skillReason,
          availabilityReason,
        ],
      MatchingStrategyType.bestSkillMatch => [
          skillReason,
          proximityReason,
          trustReason,
          availabilityReason,
        ],
      MatchingStrategyType.balanced => [
          proximityReason,
          skillReason,
          trustReason,
          availabilityReason,
        ],
    };

    return ordered.whereType<String>().toList();
  }
}
