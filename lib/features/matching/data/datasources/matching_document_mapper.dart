import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/profiles/data/models/user_profile_dto.dart';

/// Pure Firestore-document -> value mapping for the matching data source,
/// split out so the parsing rules can be tested without a Firestore
/// instance. Everything here is lenient on purpose: a single malformed
/// `profiles` or `users` document must make that one candidate drop out of
/// the results, never fail the whole search.

/// The Cloud Function writes `trust_scores.score` on a 0–100 scale
/// (`min(100, completedSessions * 5 + averageRating * 10)`), while every
/// [MatchingStrategy] and the UI treat trust as 0.0–1.0. Normalising here,
/// at the data boundary, keeps the domain's scale unchanged.
double normalizeTrustScore(num rawScore) =>
    (rawScore.toDouble() / 100).clamp(0.0, 1.0);

/// Parses a stored role name, or `null` when it is missing or not a known
/// [UserRole] (instead of throwing like `UserRole.values.byName`).
UserRole? parseUserRole(String? name) {
  if (name == null) return null;
  for (final role in UserRole.values) {
    if (role.name == name) return role;
  }
  return null;
}

/// Builds a [UserProfileDto] from a `profiles/{userId}` document, carrying
/// every field the matching strategies and cards read — including
/// `languagesSpoken`, `photoUrl` and the optional safety fields.
///
/// Returns `null` when the document has no usable `geoPoint`: such a
/// profile cannot be placed or ranked, so it is skipped.
UserProfileDto? profileDtoFromDocument(String userId, Map<String, dynamic> data) {
  final geoPoint = data['geoPoint'];
  if (geoPoint is! GeoPoint) return null;

  return UserProfileDto(
    userId: userId,
    displayName: data['displayName'] as String? ?? '',
    photoUrl: data['photoUrl'] as String?,
    bio: data['bio'] as String? ?? '',
    locality: data['locality'] as String? ?? '',
    latitude: geoPoint.latitude,
    longitude: geoPoint.longitude,
    skillsOffered: _stringList(data['skillsOffered']),
    helpNeeded: _stringList(data['helpNeeded']),
    availabilityWindows: ((data['availabilityWindows'] as List?) ?? const [])
        .whereType<Map>()
        .map((window) => Map<String, dynamic>.from(window))
        .toList(),
    accessibilityPrefs: Map<String, dynamic>.from(
      (data['accessibilityPrefs'] as Map?) ?? const <String, dynamic>{},
    ),
    emergencyContactName: data['emergencyContactName'] as String?,
    emergencyContactPhone: data['emergencyContactPhone'] as String?,
    languagesSpoken: _stringList(data['languagesSpoken']),
    safetyPreferences: _stringList(data['safetyPreferences']),
  );
}

List<String> _stringList(Object? value) =>
    value is List ? List<String>.from(value) : <String>[];
