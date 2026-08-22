import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';

/// Pure scoring strategy — new matching heuristics are added as a new
/// implementation of this interface (Open/Closed Principle), never by
/// branching inside an existing one.
abstract class MatchingStrategy {
  double score(MatchCandidate candidate, MatchCriteria criteria);
}

/// Runtime-facing counterpart to the compile-time Open/Closed pattern above
/// — lets a search request pick which [MatchingStrategy] ranks its results
/// (see [MatchCriteria.strategyType]) without the caller needing to
/// construct or know about the concrete strategy classes. Adding a new
/// strategy means adding one case here alongside its class.
enum MatchingStrategyType {
  balanced('Balanced'),
  nearest('Nearest'),
  mostTrusted('Most trusted'),
  bestSkillMatch('Best skill match');

  const MatchingStrategyType(this.label);

  /// Short, user-facing name — e.g. for a strategy picker on MatchingScreen.
  final String label;

  MatchingStrategy toStrategy() {
    switch (this) {
      case MatchingStrategyType.balanced:
        return const DefaultMatchingStrategy();
      case MatchingStrategyType.nearest:
        return const ProximityFirstStrategy();
      case MatchingStrategyType.mostTrusted:
        return const TrustFirstStrategy();
      case MatchingStrategyType.bestSkillMatch:
        return const SkillMatchFirstStrategy();
    }
  }
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

/// The three raw signals every strategy below blends, factored out so
/// [ProximityFirstStrategy], [TrustFirstStrategy] and
/// [SkillMatchFirstStrategy] don't each re-derive them — [DefaultMatchingStrategy]
/// above is untouched and keeps its own inline copies, since it predates
/// these and stays as the one hand-written reference implementation.
double _proximityScore(MatchCandidate candidate, MatchCriteria criteria) {
  return (1 - (candidate.distanceKm / (criteria.radiusKm == 0 ? 1 : criteria.radiusKm)))
      .clamp(0.0, 1.0);
}

double _trustComponent(MatchCandidate candidate) => candidate.trustScore.clamp(0.0, 1.0);

double _skillOverlap(MatchCandidate candidate, MatchCriteria criteria) {
  return criteria.requiredSkills.isEmpty
      ? 1.0
      : criteria.requiredSkills
              .where((skill) => candidate.profile.skillsOffered.contains(skill))
              .length /
          criteria.requiredSkills.length;
}

/// For a searcher who cares most about "who's close by" — a companion
/// visiting in person, say. Weights proximity far above trust and skill
/// overlap, the reverse emphasis of [DefaultMatchingStrategy].
class ProximityFirstStrategy implements MatchingStrategy {
  const ProximityFirstStrategy();

  @override
  double score(MatchCandidate candidate, MatchCriteria criteria) {
    return (_proximityScore(candidate, criteria) * 0.7) +
        (_trustComponent(candidate) * 0.15) +
        (_skillOverlap(candidate, criteria) * 0.15);
  }
}

/// For a searcher who cares most about safety/reliability over convenience —
/// weights trust score far above proximity and skill overlap.
class TrustFirstStrategy implements MatchingStrategy {
  const TrustFirstStrategy();

  @override
  double score(MatchCandidate candidate, MatchCriteria criteria) {
    return (_trustComponent(candidate) * 0.7) +
        (_proximityScore(candidate, criteria) * 0.15) +
        (_skillOverlap(candidate, criteria) * 0.15);
  }
}

/// For a searcher whose need is specific enough that the right skill set
/// matters more than distance or track record — weights skill overlap far
/// above proximity and trust.
class SkillMatchFirstStrategy implements MatchingStrategy {
  const SkillMatchFirstStrategy();

  @override
  double score(MatchCandidate candidate, MatchCriteria criteria) {
    return (_skillOverlap(candidate, criteria) * 0.7) +
        (_proximityScore(candidate, criteria) * 0.15) +
        (_trustComponent(candidate) * 0.15);
  }
}
