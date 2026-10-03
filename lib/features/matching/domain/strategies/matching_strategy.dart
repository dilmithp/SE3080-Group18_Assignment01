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
  bestSkillMatch('Best skill match'),
  languageFirst('Shares my language'),
  availabilityFirst('Free when I am');

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
      case MatchingStrategyType.languageFirst:
        return const LanguageFirstStrategy();
      case MatchingStrategyType.availabilityFirst:
        return const AvailabilityFirstStrategy();
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

/// Share of the searcher's preferred languages the candidate speaks. With no
/// preference, returns 1.0 so language does not change the ranking.
double _languageOverlap(MatchCandidate candidate, MatchCriteria criteria) {
  if (criteria.preferredLanguages.isEmpty) return 1.0;
  final spoken = candidate.profile.languagesSpoken.map((l) => l.toLowerCase()).toSet();
  final shared = criteria.preferredLanguages
      .where((l) => spoken.contains(l.toLowerCase()))
      .length;
  return shared / criteria.preferredLanguages.length;
}

/// Share of the searcher's preferred days the candidate is available on.
/// With no preference, returns 1.0.
double _availabilityOverlap(MatchCandidate candidate, MatchCriteria criteria) {
  if (criteria.preferredTimes.isEmpty) return 1.0;
  final availableDays =
      candidate.profile.availabilityWindows.map((w) => w.dayOfWeek).toSet();
  final matched = criteria.preferredTimes.where(availableDays.contains).length;
  return matched / criteria.preferredTimes.length;
}

/// For a searcher who needs someone who speaks their language, so they can
/// talk comfortably during a visit.
class LanguageFirstStrategy implements MatchingStrategy {
  const LanguageFirstStrategy();

  @override
  double score(MatchCandidate candidate, MatchCriteria criteria) {
    return (_languageOverlap(candidate, criteria) * 0.6) +
        (_proximityScore(candidate, criteria) * 0.2) +
        (_trustComponent(candidate) * 0.2);
  }
}

/// For a searcher whose main constraint is timing: ranks volunteers who are
/// free on the days they asked for above everything else.
class AvailabilityFirstStrategy implements MatchingStrategy {
  const AvailabilityFirstStrategy();

  @override
  double score(MatchCandidate candidate, MatchCriteria criteria) {
    return (_availabilityOverlap(candidate, criteria) * 0.6) +
        (_proximityScore(candidate, criteria) * 0.2) +
        (_trustComponent(candidate) * 0.2);
  }
}
