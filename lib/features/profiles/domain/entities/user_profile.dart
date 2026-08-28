import 'package:elderly_companion/features/profiles/domain/entities/accessibility_preferences.dart';
import 'package:elderly_companion/features/profiles/domain/entities/availability_window.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';

/// Pure domain entity — zero `package:firebase_*` imports. Data-layer DTOs
/// (see data/models/user_profile_dto.dart) convert Firestore documents to
/// and from this type; nothing outside data/ should know Firestore exists.
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.bio,
    required this.locality,
    required this.geoPoint,
    required this.skillsOffered,
    required this.helpNeeded,
    required this.availabilityWindows,
    required this.accessibilityPrefs,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final String bio;
  final String locality;
  final GeoCoordinates geoPoint;
  final List<String> skillsOffered;
  final List<String> helpNeeded;
  final List<AvailabilityWindow> availabilityWindows;
  final AccessibilityPreferences accessibilityPrefs;

  /// Optional safety contact, shown/dialable via [EmergencyContactCard].
  /// Nullable and optional so no existing call site breaks.
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? locality,
    GeoCoordinates? geoPoint,
    List<String>? skillsOffered,
    List<String>? helpNeeded,
    List<AvailabilityWindow>? availabilityWindows,
    AccessibilityPreferences? accessibilityPrefs,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      locality: locality ?? this.locality,
      geoPoint: geoPoint ?? this.geoPoint,
      skillsOffered: skillsOffered ?? this.skillsOffered,
      helpNeeded: helpNeeded ?? this.helpNeeded,
      availabilityWindows: availabilityWindows ?? this.availabilityWindows,
      accessibilityPrefs: accessibilityPrefs ?? this.accessibilityPrefs,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          bio == other.bio &&
          locality == other.locality &&
          geoPoint == other.geoPoint &&
          _listEquals(skillsOffered, other.skillsOffered) &&
          _listEquals(helpNeeded, other.helpNeeded) &&
          _listEquals(availabilityWindows, other.availabilityWindows) &&
          accessibilityPrefs == other.accessibilityPrefs &&
          emergencyContactName == other.emergencyContactName &&
          emergencyContactPhone == other.emergencyContactPhone;

  @override
  int get hashCode => Object.hash(
        userId,
        displayName,
        photoUrl,
        bio,
        locality,
        geoPoint,
        Object.hashAll(skillsOffered),
        Object.hashAll(helpNeeded),
        Object.hashAll(availabilityWindows),
        accessibilityPrefs,
        emergencyContactName,
        emergencyContactPhone,
      );
}

/// Deep element-wise list equality. Hand-rolled (rather than pulling in
/// `package:collection`'s `ListEquality`) to avoid adding an undeclared
/// dependency — see pubspec.yaml, which does not list `collection` directly.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
