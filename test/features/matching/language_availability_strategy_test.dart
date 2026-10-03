import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';
import 'package:elderly_companion/features/matching/domain/strategies/matching_strategy.dart';
import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/domain/entities/availability_window.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

MatchCandidate _candidate({
  List<String> languages = const [],
  List<String> days = const [],
  double distanceKm = 10,
  double trustScore = 0,
}) {
  final profile = UserProfile(
    userId: 'candidate',
    displayName: 'Candidate',
    bio: '',
    locality: 'Colombo',
    geoPoint: const GeoCoordinates(latitude: 0, longitude: 0),
    skillsOffered: const [],
    helpNeeded: const [],
    availabilityWindows: [
      for (final d in days)
        AvailabilityWindow(dayOfWeek: d, startTime: '09:00', endTime: '11:00'),
    ],
    accessibilityPrefs: const AccessibilityPreferences(
      largeText: false,
      highContrast: false,
      simplifiedInterface: false,
    ),
    languagesSpoken: languages,
  );
  return MatchCandidate(
    userId: 'candidate',
    profile: profile,
    distanceKm: distanceKm,
    trustScore: trustScore,
    matchScore: 0,
    matchReasons: const [],
  );
}

MatchCriteria _criteria({
  List<String> languages = const [],
  List<String> times = const [],
}) {
  return MatchCriteria(
    locality: 'Colombo',
    radiusKm: 10,
    requiredSkills: const [],
    preferredTimes: times,
    viewerId: 'viewer',
    viewerRole: UserRole.elderly,
    preferredLanguages: languages,
  );
}

void main() {
  group('LanguageFirstStrategy', () {
    test('a shared language gives the full 0.6 language weight', () {
      final candidate = _candidate(languages: const ['Sinhala']);
      final criteria = _criteria(languages: const ['Sinhala']);

      expect(const LanguageFirstStrategy().score(candidate, criteria), closeTo(0.6, 1e-9));
    });

    test('language matching ignores case', () {
      final candidate = _candidate(languages: const ['sinhala']);
      final criteria = _criteria(languages: const ['SINHALA']);

      expect(const LanguageFirstStrategy().score(candidate, criteria), closeTo(0.6, 1e-9));
    });

    test('half of the preferred languages gives half the language weight', () {
      final candidate = _candidate(languages: const ['English']);
      final criteria = _criteria(languages: const ['English', 'Tamil']);

      expect(const LanguageFirstStrategy().score(candidate, criteria), closeTo(0.3, 1e-9));
    });

    test('with no language preference the language term is neutral', () {
      final candidate = _candidate();
      final criteria = _criteria();

      // Language contributes its full 0.6 when the searcher has no preference.
      expect(const LanguageFirstStrategy().score(candidate, criteria), closeTo(0.6, 1e-9));
    });

    test('a candidate who shares the language outranks one who does not', () {
      final shares = _candidate(languages: const ['Tamil'], trustScore: 0.2);
      final noShare = _candidate(languages: const ['English'], trustScore: 0.9);
      final criteria = _criteria(languages: const ['Tamil']);

      const strategy = LanguageFirstStrategy();
      expect(strategy.score(shares, criteria), greaterThan(strategy.score(noShare, criteria)));
    });
  });

  group('AvailabilityFirstStrategy', () {
    test('being free on every requested day gives the full 0.6 availability weight', () {
      final candidate = _candidate(days: const ['Mon', 'Wed']);
      final criteria = _criteria(times: const ['Mon', 'Wed']);

      expect(const AvailabilityFirstStrategy().score(candidate, criteria), closeTo(0.6, 1e-9));
    });

    test('free on one of two requested days gives half the availability weight', () {
      final candidate = _candidate(days: const ['Mon']);
      final criteria = _criteria(times: const ['Mon', 'Fri']);

      expect(const AvailabilityFirstStrategy().score(candidate, criteria), closeTo(0.3, 1e-9));
    });

    test('a candidate free on the requested day outranks one who is not', () {
      final free = _candidate(days: const ['Sat'], trustScore: 0.1);
      final busy = _candidate(days: const ['Tue'], trustScore: 0.9);
      final criteria = _criteria(times: const ['Sat']);

      const strategy = AvailabilityFirstStrategy();
      expect(strategy.score(free, criteria), greaterThan(strategy.score(busy, criteria)));
    });
  });

  group('MatchingStrategyType', () {
    test('the new types map to their strategies', () {
      expect(MatchingStrategyType.languageFirst.toStrategy(), isA<LanguageFirstStrategy>());
      expect(
        MatchingStrategyType.availabilityFirst.toStrategy(),
        isA<AvailabilityFirstStrategy>(),
      );
    });
  });

  group('MatchCriteria', () {
    test('preferred languages default to empty, so existing searches are unchanged', () {
      const criteria = MatchCriteria(
        locality: 'Colombo',
        radiusKm: 5,
        requiredSkills: [],
        preferredTimes: [],
        viewerId: 'v',
        viewerRole: UserRole.elderly,
      );

      expect(criteria.preferredLanguages, isEmpty);
    });

    test('changing only the preferred languages makes criteria unequal', () {
      final a = _criteria(languages: const ['English']);
      final b = _criteria(languages: const ['Tamil']);

      expect(a == b, isFalse);
    });
  });
}
