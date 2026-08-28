import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/domain/entities/availability_window.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';

part 'user_profile_dto.freezed.dart';
part 'user_profile_dto.g.dart';

/// Firestore-shaped DTO for the `profiles` collection. Converts to/from the
/// pure [UserProfile] domain entity — see [toEntity] / [UserProfileDto.fromEntity].
///
/// `latitude`/`longitude` are stored flattened (rather than a nested
/// `GeoPoint`-shaped DTO) so this class stays plain-JSON with zero custom
/// converters; the data source is responsible for bridging Firestore's
/// `GeoPoint` type at the boundary. Likewise, `availabilityWindows` and
/// `accessibilityPrefs` use raw `List<Map<String, dynamic>>` / `Map<String,
/// dynamic>` rather than nested DTOs — json_serializable handles those
/// natively with zero extra codegen classes, which keeps this low-risk.
@freezed
class UserProfileDto with _$UserProfileDto {
  const UserProfileDto._();

  const factory UserProfileDto({
    required String userId,
    required String displayName,
    String? photoUrl,
    required String bio,
    required String locality,
    required double latitude,
    required double longitude,
    required List<String> skillsOffered,
    required List<String> helpNeeded,
    required List<Map<String, dynamic>> availabilityWindows,
    required Map<String, dynamic> accessibilityPrefs,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) = _UserProfileDto;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  factory UserProfileDto.fromEntity(UserProfile entity) => UserProfileDto(
        userId: entity.userId,
        displayName: entity.displayName,
        photoUrl: entity.photoUrl,
        bio: entity.bio,
        locality: entity.locality,
        latitude: entity.geoPoint.latitude,
        longitude: entity.geoPoint.longitude,
        skillsOffered: entity.skillsOffered,
        helpNeeded: entity.helpNeeded,
        availabilityWindows: entity.availabilityWindows
            .map(
              (window) => <String, dynamic>{
                'dayOfWeek': window.dayOfWeek,
                'startTime': window.startTime,
                'endTime': window.endTime,
              },
            )
            .toList(),
        accessibilityPrefs: <String, dynamic>{
          'largeText': entity.accessibilityPrefs.largeText,
          'highContrast': entity.accessibilityPrefs.highContrast,
          'simplifiedInterface': entity.accessibilityPrefs.simplifiedInterface,
          'communicationNotes': entity.accessibilityPrefs.communicationNotes,
        },
        emergencyContactName: entity.emergencyContactName,
        emergencyContactPhone: entity.emergencyContactPhone,
      );

  UserProfile toEntity() => UserProfile(
        userId: userId,
        displayName: displayName,
        photoUrl: photoUrl,
        bio: bio,
        locality: locality,
        geoPoint: GeoCoordinates(latitude: latitude, longitude: longitude),
        skillsOffered: skillsOffered,
        helpNeeded: helpNeeded,
        availabilityWindows: availabilityWindows
            .map(
              (window) => AvailabilityWindow(
                dayOfWeek: window['dayOfWeek'] as String,
                startTime: window['startTime'] as String,
                endTime: window['endTime'] as String,
              ),
            )
            .toList(),
        accessibilityPrefs: AccessibilityPreferences(
          largeText: accessibilityPrefs['largeText'] as bool? ?? false,
          highContrast: accessibilityPrefs['highContrast'] as bool? ?? false,
          simplifiedInterface:
              accessibilityPrefs['simplifiedInterface'] as bool? ?? false,
          communicationNotes: accessibilityPrefs['communicationNotes'] as String?,
        ),
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      );
}
