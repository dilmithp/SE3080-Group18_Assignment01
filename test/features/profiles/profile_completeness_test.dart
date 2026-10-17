import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/domain/entities/availability_window.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';
import 'package:elderly_companion/features/profiles/domain/entities/profile_completeness.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfile _profile({
  String displayName = '',
  String? photoUrl,
  String bio = '',
  String locality = '',
  GeoCoordinates geoPoint = const GeoCoordinates(latitude: 0, longitude: 0),
  List<String> languagesSpoken = const [],
  List<String> skillsOffered = const [],
  List<String> helpNeeded = const [],
  List<AvailabilityWindow> availabilityWindows = const [],
  String? emergencyContactPhone,
}) {
  return UserProfile(
    userId: 'u1',
    displayName: displayName,
    photoUrl: photoUrl,
    bio: bio,
    locality: locality,
    geoPoint: geoPoint,
    skillsOffered: skillsOffered,
    helpNeeded: helpNeeded,
    availabilityWindows: availabilityWindows,
    accessibilityPrefs: const AccessibilityPreferences(
      largeText: false,
      highContrast: false,
      simplifiedInterface: false,
    ),
    emergencyContactPhone: emergencyContactPhone,
    languagesSpoken: languagesSpoken,
  );
}

UserProfile _fullProfile() => _profile(
      displayName: 'Mary Silva',
      photoUrl: 'https://example.com/p.jpg',
      bio: 'Retired teacher',
      locality: 'Colombo 07',
      geoPoint: const GeoCoordinates(latitude: 6.9, longitude: 79.86),
      languagesSpoken: const ['English', 'Sinhala'],
      skillsOffered: const ['gardening'],
      helpNeeded: const ['grocery runs'],
      availabilityWindows: const [
        AvailabilityWindow(dayOfWeek: 'Mon', startTime: '09:00', endTime: '11:00'),
      ],
      emergencyContactPhone: '0771234567',
    );

void main() {
  group('ProfileCompleteness', () {
    test('an empty profile scores 0% and lists every item as missing', () {
      final c = ProfileCompleteness.of(_profile());

      expect(c.completedCount, 0);
      expect(c.percent, 0);
      expect(c.isComplete, isFalse);
      expect(c.missing.length, c.totalCount);
    });

    test('a fully filled profile is complete with nothing missing', () {
      final c = ProfileCompleteness.of(_fullProfile());

      expect(c.percent, 100);
      expect(c.isComplete, isTrue);
      expect(c.missing, isEmpty);
    });

    test('percent is the rounded share of completed items', () {
      final c = ProfileCompleteness.of(_profile(displayName: 'Mary'));

      expect(c.completedCount, 1);
      expect(c.percent, (1 / c.totalCount * 100).round());
      expect(c.missing, isNot(contains('Add your name')));
    });

    test('whitespace-only text fields do not count as completed', () {
      final c = ProfileCompleteness.of(_profile(displayName: '   ', bio: '  '));

      expect(c.missing, contains('Add your name'));
      expect(c.missing, contains('Write a short bio'));
    });

    test('an unset map location (0,0) is treated as missing', () {
      final c = ProfileCompleteness.of(_profile());

      expect(c.missing, contains('Set your location on the map'));
    });

    test('languages are counted and drive the missing-item label', () {
      final without = ProfileCompleteness.of(_fullProfile().copyWith(languagesSpoken: const []));
      final withLang = ProfileCompleteness.of(_fullProfile());

      expect(without.missing, ['List languages you speak']);
      expect(withLang.missing, isEmpty);
    });

    test('blank emergency contact phone is not counted', () {
      final c = ProfileCompleteness.of(_profile(emergencyContactPhone: '  '));

      expect(c.missing, contains('Add an emergency contact'));
    });
  });
}
