import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';
import 'package:elderly_companion/features/matching/domain/repositories/matching_repository.dart';
import 'package:elderly_companion/features/matching/domain/strategies/matching_strategy.dart';
import 'package:elderly_companion/features/matching/domain/usecases/find_matches_usecase.dart';
import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/domain/entities/availability_window.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract [MatchingRepository] interface (never the Firebase
/// implementation) per the team's testing pattern — see
/// test/features/auth_trust/auth_repository_test.dart for the canonical
/// shape this copies.
class MockMatchingRepository extends Mock implements MatchingRepository {}

UserProfile _profile({
  required String userId,
  required String locality,
  List<String> skillsOffered = const [],
  List<AvailabilityWindow> availabilityWindows = const [],
}) {
  return UserProfile(
    userId: userId,
    displayName: 'User $userId',
    bio: '',
    locality: locality,
    geoPoint: const GeoCoordinates(latitude: 0, longitude: 0),
    skillsOffered: skillsOffered,
    helpNeeded: const [],
    availabilityWindows: availabilityWindows,
    accessibilityPrefs: const AccessibilityPreferences(
      largeText: false,
      highContrast: false,
      simplifiedInterface: false,
    ),
  );
}

void main() {
  late MockMatchingRepository matchingRepository;
  late FindMatchesUseCase useCase;

  setUp(() {
    matchingRepository = MockMatchingRepository();
    useCase = FindMatchesUseCase(matchingRepository);
  });

  const criteria = MatchCriteria(
    locality: 'Colombo',
    radiusKm: 10,
    requiredSkills: ['gardening'],
    preferredTimes: [],
    origin: GeoCoordinates(latitude: 6.9271, longitude: 79.8612),
  );

  final lowScoreCandidate = MatchCandidate(
    userId: 'user-1',
    profile: _profile(userId: 'user-1', locality: 'Colombo'),
    distanceKm: 9,
    trustScore: 0.2,
    matchScore: 0.0,
    matchReasons: const [],
  );

  final highScoreCandidate = MatchCandidate(
    userId: 'user-2',
    profile: _profile(
      userId: 'user-2',
      locality: 'Colombo',
      skillsOffered: ['gardening'],
    ),
    distanceKm: 1,
    trustScore: 0.9,
    matchScore: 0.0,
    matchReasons: const [],
  );

  group('FindMatchesUseCase', () {
    test('scores and sorts candidates descending by matchScore', () async {
      when(() => matchingRepository.findMatches(criteria)).thenAnswer(
        (_) async => Right([lowScoreCandidate, highScoreCandidate]),
      );

      final result = await useCase(criteria);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected a Right(List<MatchCandidate>)'),
        (candidates) {
          expect(candidates.map((c) => c.userId), ['user-2', 'user-1']);
          expect(candidates.first.matchScore, greaterThan(candidates.last.matchScore));
        },
      );
    });

    test('attaches human-readable matchReasons for distance, skills and trust', () async {
      when(() => matchingRepository.findMatches(criteria)).thenAnswer(
        (_) async => Right([highScoreCandidate]),
      );

      final result = await useCase(criteria);

      result.fold(
        (_) => fail('Expected a Right(List<MatchCandidate>)'),
        (candidates) {
          final reasons = candidates.single.matchReasons;
          expect(reasons, contains('1.0 km away'));
          expect(reasons, contains('Offers gardening'));
          expect(reasons, contains('Highly trusted (90% trust score)'));
        },
      );
    });

    test('attaches an Available reason when preferredTimes overlap the '
        "candidate's availability", () async {
      final criteriaWithPreferredTimes = criteria.copyWith(
        preferredTimes: const ['Monday', 'Friday'],
      );
      final available = MatchCandidate(
        userId: 'user-3',
        profile: _profile(
          userId: 'user-3',
          locality: 'Colombo',
          skillsOffered: const ['gardening'],
          availabilityWindows: const [
            AvailabilityWindow(dayOfWeek: 'Monday', startTime: '09:00', endTime: '12:00'),
          ],
        ),
        distanceKm: 1,
        trustScore: 0.5,
        matchScore: 0.0,
        matchReasons: const [],
      );
      when(() => matchingRepository.findMatches(criteriaWithPreferredTimes))
          .thenAnswer((_) async => Right([available]));

      final result = await useCase(criteriaWithPreferredTimes);

      result.fold(
        (_) => fail('Expected a Right(List<MatchCandidate>)'),
        (candidates) => expect(candidates.single.matchReasons, contains('Available Monday')),
      );
    });

    test('resolves the strategy from criteria.strategyType, flipping the '
        'ranking a different strategy would produce', () async {
      // Deliberately crosses signals so balanced/nearest and mostTrusted
      // disagree on the winner: near is closer but far is more trusted.
      final near = MatchCandidate(
        userId: 'near',
        profile:
            _profile(userId: 'near', locality: 'Colombo', skillsOffered: const ['gardening']),
        distanceKm: 1,
        trustScore: 0.3,
        matchScore: 0.0,
        matchReasons: const [],
      );
      final far = MatchCandidate(
        userId: 'far',
        profile:
            _profile(userId: 'far', locality: 'Colombo', skillsOffered: const ['gardening']),
        distanceKm: 9,
        trustScore: 1.0,
        matchScore: 0.0,
        matchReasons: const [],
      );

      when(() => matchingRepository.findMatches(criteria))
          .thenAnswer((_) async => Right([near, far]));
      final balancedResult = await useCase(criteria);
      balancedResult.fold(
        (_) => fail('Expected a Right(List<MatchCandidate>)'),
        (candidates) => expect(candidates.map((c) => c.userId), ['near', 'far']),
      );

      final trustFirstCriteria = criteria.copyWith(
        strategyType: MatchingStrategyType.mostTrusted,
      );
      when(() => matchingRepository.findMatches(trustFirstCriteria))
          .thenAnswer((_) async => Right([near, far]));
      final trustFirstResult = await useCase(trustFirstCriteria);
      trustFirstResult.fold(
        (_) => fail('Expected a Right(List<MatchCandidate>)'),
        (candidates) {
          expect(candidates.map((c) => c.userId), ['far', 'near']);
          expect(candidates.first.matchReasons.first, contains('Highly trusted'));
        },
      );
    });

    test('propagates a Left(Failure) from the repository unchanged', () async {
      when(() => matchingRepository.findMatches(criteria)).thenAnswer(
        (_) async => const Left(UnknownFailure('boom')),
      );

      final result = await useCase(criteria);

      expect(result, const Left<Failure, List<MatchCandidate>>(UnknownFailure('boom')));
      verify(() => matchingRepository.findMatches(criteria)).called(1);
    });
  });
}
