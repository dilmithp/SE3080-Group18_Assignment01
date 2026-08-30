import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/matching/data/models/match_candidate_dto.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/profiles/data/models/user_profile_dto.dart';
import 'package:elderly_companion/features/profiles/domain/entities/geo_coordinates.dart';

/// Raw Firebase calls for matching — the only place in this feature
/// allowed to import Firebase-backed services. Throws the exceptions in
/// core/error/exceptions.dart; repository implementations translate those
/// into [Failure]s.
abstract class MatchingRemoteDataSource {
  Future<List<MatchCandidateDto>> findMatches({
    required String locality,
    required double radiusKm,
    required List<String> requiredSkills,
    required List<String> preferredTimes,
    required String viewerId,
    required UserRole viewerRole,
    GeoCoordinates? origin,
  });
}

/// Whether [viewerRole] may see a candidate whose own role is
/// [candidateRole]: elderly members only see volunteers; volunteers see
/// both elderly members and other volunteers; admins see everyone.
bool _canSee({required UserRole viewerRole, required UserRole candidateRole}) {
  return switch (viewerRole) {
    UserRole.admin => true,
    UserRole.volunteer =>
      candidateRole == UserRole.volunteer || candidateRole == UserRole.elderly,
    UserRole.elderly => candidateRole == UserRole.volunteer,
  };
}

const _earthRadiusKm = 6371.0;

double _degToRad(double deg) => deg * (math.pi / 180);

/// Great-circle distance between two points, in kilometres.
double _haversineKm(GeoCoordinates a, GeoCoordinates b) {
  final dLat = _degToRad(b.latitude - a.latitude);
  final dLon = _degToRad(b.longitude - a.longitude);
  final lat1 = _degToRad(a.latitude);
  final lat2 = _degToRad(b.latitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return _earthRadiusKm * c;
}

class FirebaseMatchingRemoteDataSource implements MatchingRemoteDataSource {
  FirebaseMatchingRemoteDataSource({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  @override
  Future<List<MatchCandidateDto>> findMatches({
    required String locality,
    required double radiusKm,
    required List<String> requiredSkills,
    required List<String> preferredTimes,
    required String viewerId,
    required UserRole viewerRole,
    GeoCoordinates? origin,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestoreService.collection(AppConfig.profilesCollection);
      // An exact `locality` string match would silently exclude a
      // genuinely-nearby candidate whose free-text locality happens to be
      // spelled or named differently (neighbouring towns, "Colombo" vs
      // "Colombo 5", etc). Once a real origin coordinate is available, the
      // Haversine + radiusKm filter below is the correct, more forgiving
      // way to bound the search — the locality string is only needed as a
      // fallback when there is no coordinate to search from at all.
      if (origin == null) {
        query = query.where('locality', isEqualTo: locality);
      }
      if (requiredSkills.isNotEmpty) {
        query = query.where('skillsOffered', arrayContainsAny: requiredSkills);
      }

      final snapshot = await query.get();

      final candidates = <MatchCandidateDto>[];
      for (final doc in snapshot.docs) {
        if (doc.id == viewerId) continue;

        final candidateRoleName = await _firestoreService.getDocument<String>(
          collectionPath: AppConfig.usersCollection,
          docId: doc.id,
          fromJson: (data) => data['role'] as String,
        );
        if (candidateRoleName == null) continue;
        final candidateRole = UserRole.values.byName(candidateRoleName);
        if (!_canSee(viewerRole: viewerRole, candidateRole: candidateRole)) {
          continue;
        }

        final data = doc.data();
        final geoPoint = data['geoPoint'] as GeoPoint;
        final profileDto = UserProfileDto(
          userId: doc.id,
          displayName: data['displayName'] as String,
          photoUrl: data['photoUrl'] as String?,
          bio: data['bio'] as String,
          locality: data['locality'] as String,
          latitude: geoPoint.latitude,
          longitude: geoPoint.longitude,
          skillsOffered: List<String>.from(data['skillsOffered'] as List),
          helpNeeded: List<String>.from(data['helpNeeded'] as List),
          availabilityWindows: (data['availabilityWindows'] as List)
              .map((window) => Map<String, dynamic>.from(window as Map))
              .toList(),
          accessibilityPrefs:
              Map<String, dynamic>.from(data['accessibilityPrefs'] as Map),
        );
        final profileEntity = profileDto.toEntity();

        final distanceKm = origin == null
            ? 0.0
            : _haversineKm(origin, profileEntity.geoPoint);
        if (origin != null && radiusKm > 0 && distanceKm > radiusKm) {
          continue;
        }

        if (preferredTimes.isNotEmpty) {
          final availableDays =
              profileEntity.availabilityWindows.map((w) => w.dayOfWeek).toSet();
          if (!preferredTimes.any(availableDays.contains)) {
            continue;
          }
        }

        final trustScore = await _firestoreService.getDocument<double>(
              collectionPath: AppConfig.trustScoresCollection,
              docId: doc.id,
              fromJson: (data) => (data['score'] as num).toDouble(),
            ) ??
            0.0;

        final candidate = MatchCandidate(
          userId: doc.id,
          profile: profileEntity,
          distanceKm: distanceKm,
          trustScore: trustScore,
          matchScore: 0.0,
          matchReasons: const [],
        );
        candidates.add(MatchCandidateDto.fromEntity(candidate));
      }

      return candidates;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } catch (_) {
      throw const ServerException();
    }
  }
}
