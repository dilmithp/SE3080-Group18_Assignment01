import 'package:elderly_companion/features/profiles/data/models/user_profile_dto.dart';
import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';
import 'package:elderly_companion/features/profiles/domain/entities/safety_preference.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfile _profile({List<String> safety = const []}) {
  return UserProfile(
    userId: 'u1',
    displayName: 'Mary',
    bio: '',
    locality: 'Colombo 07',
    geoPoint: const GeoCoordinates(latitude: 6.9, longitude: 79.86),
    skillsOffered: const [],
    helpNeeded: const [],
    availabilityWindows: const [],
    accessibilityPrefs: const AccessibilityPreferences(
      largeText: false,
      highContrast: false,
      simplifiedInterface: false,
    ),
    safetyPreferences: safety,
  );
}

void main() {
  group('safety preferences', () {
    test('options list has no duplicates and is not empty', () {
      expect(safetyPreferenceOptions, isNotEmpty);
      expect(safetyPreferenceOptions.toSet().length, safetyPreferenceOptions.length);
    });

    test('a profile round-trips through the DTO with its safety choices', () {
      final original = _profile(safety: const ['Meet in a public place first']);

      final restored = UserProfileDto.fromEntity(original).toEntity();

      expect(restored.safetyPreferences, ['Meet in a public place first']);
      expect(restored, original);
    });

    test('a profile saved before this field existed loads with no choices', () {
      final dto = UserProfileDto.fromEntity(_profile());

      expect(dto.toEntity().safetyPreferences, isEmpty);
    });

    test('changing only the safety choices makes two profiles unequal', () {
      final a = _profile(safety: const ['Daytime visits only']);
      final b = _profile(safety: const ['No overnight visits']);

      expect(a == b, isFalse);
    });

    test('copyWith replaces the safety choices', () {
      final updated = _profile().copyWith(safetyPreferences: const ['Daytime visits only']);

      expect(updated.safetyPreferences, ['Daytime visits only']);
    });
  });
}
