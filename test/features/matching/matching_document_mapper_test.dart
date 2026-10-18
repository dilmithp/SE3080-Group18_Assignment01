import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/matching/data/datasources/matching_document_mapper.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';
import 'package:elderly_companion/features/matching/domain/strategies/matching_strategy.dart';

Map<String, dynamic> _doc({Map<String, dynamic>? overrides}) => {
      'displayName': 'Nimali',
      'photoUrl': 'https://example.com/n.jpg',
      'bio': 'Happy to chat',
      'locality': 'Colombo',
      'geoPoint': const GeoPoint(6.9271, 79.8612),
      'skillsOffered': ['cooking'],
      'helpNeeded': <String>[],
      'availabilityWindows': [
        {'dayOfWeek': 'Monday', 'startTime': '09:00', 'endTime': '12:00'},
      ],
      'accessibilityPrefs': {'largeText': true},
      'languagesSpoken': ['Sinhala', 'English'],
      'safetyPreferences': ['public_places_only'],
      'emergencyContactName': 'Kamal',
      'emergencyContactPhone': '0771234567',
      ...?overrides,
    };

void main() {
  group('profileDtoFromDocument', () {
    test('carries languagesSpoken, photoUrl and safety fields through', () {
      final profile = profileDtoFromDocument('u1', _doc())!.toEntity();

      expect(profile.languagesSpoken, ['Sinhala', 'English']);
      expect(profile.photoUrl, 'https://example.com/n.jpg');
      expect(profile.safetyPreferences, ['public_places_only']);
      expect(profile.emergencyContactName, 'Kamal');
      expect(profile.availabilityWindows.single.dayOfWeek, 'Monday');
    });

    test('tolerates older profiles that lack the optional fields', () {
      final data = _doc()
        ..remove('languagesSpoken')
        ..remove('safetyPreferences')
        ..remove('photoUrl');

      final profile = profileDtoFromDocument('u1', data)!.toEntity();

      expect(profile.languagesSpoken, isEmpty);
      expect(profile.safetyPreferences, isEmpty);
      expect(profile.photoUrl, isNull);
    });

    test('returns null (skips the candidate) when geoPoint is missing', () {
      expect(profileDtoFromDocument('u1', _doc()..remove('geoPoint')), isNull);
      expect(
        profileDtoFromDocument('u1', _doc(overrides: {'geoPoint': 'nope'})),
        isNull,
      );
    });

    test('a candidate built from a real document ranks on language', () {
      final profile = profileDtoFromDocument('u1', _doc())!.toEntity();
      final candidate = MatchCandidate(
        userId: 'u1',
        profile: profile,
        distanceKm: 0,
        trustScore: 0,
        matchScore: 0,
        matchReasons: const [],
      );
      const criteria = MatchCriteria(
        locality: 'Colombo',
        radiusKm: 5,
        requiredSkills: [],
        preferredTimes: [],
        viewerId: 'v',
        viewerRole: UserRole.elderly,
        preferredLanguages: ['Sinhala'],
      );

      // Language term (0.6) + full proximity at 0 km (0.2) + 0 trust.
      expect(const LanguageFirstStrategy().score(candidate, criteria), closeTo(0.8, 1e-9));
    });
  });

  group('normalizeTrustScore', () {
    test('maps the Cloud Function 0-100 scale onto 0.0-1.0', () {
      expect(normalizeTrustScore(0), 0.0);
      expect(normalizeTrustScore(35), closeTo(0.35, 1e-9));
      expect(normalizeTrustScore(100), 1.0);
    });

    test('a low-but-nonzero score no longer saturates to 1.0', () {
      expect(normalizeTrustScore(5), lessThan(0.1));
    });

    test('clamps out-of-range values', () {
      expect(normalizeTrustScore(250), 1.0);
      expect(normalizeTrustScore(-4), 0.0);
    });
  });

  group('parseUserRole', () {
    test('parses known roles', () {
      expect(parseUserRole('elderly'), UserRole.elderly);
      expect(parseUserRole('volunteer'), UserRole.volunteer);
      expect(parseUserRole('admin'), UserRole.admin);
    });

    test('returns null instead of throwing for missing or unknown roles', () {
      expect(parseUserRole(null), isNull);
      expect(parseUserRole('superuser'), isNull);
    });
  });
}
