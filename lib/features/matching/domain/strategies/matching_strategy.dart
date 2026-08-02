import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';

/// Pure scoring strategy — new matching heuristics are added as a new
/// implementation of this interface (Open/Closed Principle), never by
/// branching inside an existing one.
abstract class MatchingStrategy {
  double score(MatchCandidate candidate, MatchCriteria criteria);
}

/// Weighted blend of proximity, trust and skill overlap. Pure, synchronous
/// and Firebase-free by design — it operates only on values already
/// resolved onto [MatchCandidate] and [MatchCriteria].
class DefaultMatchingStrategy implements MatchingStrategy {
  const DefaultMatchingStrategy();

  @override
  double score(MatchCandidate candidate, MatchCriteria criteria) {
    final proximityScore = (1 -
            (candidate.distanceKm / (criteria.radiusKm == 0 ? 1 : criteria.radiusKm)))
        .clamp(0.0, 1.0);
    final trustComponent = candidate.trustScore.clamp(0.0, 1.0);
    final skillOverlap = criteria.requiredSkills.isEmpty
        ? 1.0
        : criteria.requiredSkills
                .where((skill) => candidate.profile.skillsOffered.contains(skill))
                .length /
            criteria.requiredSkills.length;
    return (proximityScore * 0.4) + (trustComponent * 0.35) + (skillOverlap * 0.25);
  }
}
