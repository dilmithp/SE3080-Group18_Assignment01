import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';
import 'package:elderly_companion/features/matching/domain/strategies/matching_strategy.dart';
import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the three new strategies added alongside DefaultMatchingStrategy
/// (deliberately left untouched — see matching_strategy.dart). Each test
/// picks inputs that zero out the other two signals, so the "weights X at
/// 0.7" assertions isolate exactly the component under test, plus one
/// ranking-crossover test per strategy showing the weighting actually
/// changes which candidate comes out on top for the same two candidates.
MatchCandidate _candidate({
  required double distanceKm,
  required double trustScore,
  List<String> skillsOffered = const [],
}) {
  final profile = UserProfile(
    userId: 'candidate',
    displayName: 'Candidate',
    bio: '',
    locality: 'Colombo',
    geoPoint: const GeoCoordinates(latitude: 0, longitude: 0),
    skillsOffered: skillsOffered,
    helpNeeded: const [],
    availabilityWindows: const [],
    accessibilityPrefs: const AccessibilityPreferences(
      largeText: false,
      highContrast: false,
      simplifiedInterface: false,
    ),
  );
  return MatchCandidate(
    userId: 'candidate',
    profile: profile,
    distanceKm: distanceKm,
    trustScore: trustScore,
    matchScore: 0.0,
    matchReasons: const [],
  );
}

const criteria = MatchCriteria(
  locality: 'Colombo',
  radiusKm: 10,
  requiredSkills: ['gardening'],
  preferredTimes: [],
  viewerId: 'viewer-1',
  viewerRole: UserRole.elderly,
);

void main() {
  group('ProximityFirstStrategy', () {
    test('weights proximity at 0.7 when trust and skill overlap are zero', () {
      final candidate = _candidate(distanceKm: 0, trustScore: 0);

      expect(const ProximityFirstStrategy().score(candidate, criteria), closeTo(0.7, 1e-9));
    });

    test('ranks a close, less-trusted candidate above a far, highly-trusted one', () {
      const strategy = ProximityFirstStrategy();
      final near = _candidate(distanceKm: 1, trustScore: 0.3, skillsOffered: ['gardening']);
      final far = _candidate(distanceKm: 9, trustScore: 1.0, skillsOffered: ['gardening']);

      expect(strategy.score(near, criteria), greaterThan(strategy.score(far, criteria)));
    });
  });

  group('TrustFirstStrategy', () {
    test('weights trust at 0.7 when proximity and skill overlap are zero', () {
      final candidate = _candidate(distanceKm: 10, trustScore: 1.0);

      expect(const TrustFirstStrategy().score(candidate, criteria), closeTo(0.7, 1e-9));
    });

    test('ranks a far, highly-trusted candidate above a close, less-trusted one', () {
      const strategy = TrustFirstStrategy();
      final near = _candidate(distanceKm: 1, trustScore: 0.3, skillsOffered: ['gardening']);
      final far = _candidate(distanceKm: 9, trustScore: 1.0, skillsOffered: ['gardening']);

      expect(strategy.score(far, criteria), greaterThan(strategy.score(near, criteria)));
    });
  });

  group('SkillMatchFirstStrategy', () {
    test('weights skill overlap at 0.7 when proximity and trust are zero', () {
      final candidate = _candidate(distanceKm: 10, trustScore: 0, skillsOffered: ['gardening']);

      expect(const SkillMatchFirstStrategy().score(candidate, criteria), closeTo(0.7, 1e-9));
    });

    test('ranks a skill-matching candidate above a non-matching one at equal '
        'distance and trust', () {
      const strategy = SkillMatchFirstStrategy();
      final matching = _candidate(distanceKm: 5, trustScore: 0.5, skillsOffered: ['gardening']);
      final nonMatching = _candidate(distanceKm: 5, trustScore: 0.5);

      expect(
        strategy.score(matching, criteria),
        greaterThan(strategy.score(nonMatching, criteria)),
      );
    });
  });

  group('MatchingStrategyType.toStrategy', () {
    test('resolves each enum value to its matching concrete class', () {
      expect(MatchingStrategyType.balanced.toStrategy(), isA<DefaultMatchingStrategy>());
      expect(MatchingStrategyType.nearest.toStrategy(), isA<ProximityFirstStrategy>());
      expect(MatchingStrategyType.mostTrusted.toStrategy(), isA<TrustFirstStrategy>());
      expect(MatchingStrategyType.bestSkillMatch.toStrategy(), isA<SkillMatchFirstStrategy>());
    });
  });
}
