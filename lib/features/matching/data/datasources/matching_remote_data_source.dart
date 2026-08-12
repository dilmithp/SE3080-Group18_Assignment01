import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/features/matching/data/models/match_candidate_dto.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/profiles/data/models/user_profile_dto.dart';

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
  });
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
  }) async {
    // [MatchCriteria] carries no origin coordinate, so true geo-distance
    // ranking isn't computable client-side here; a real implementation
    // might use a Cloud Function for that. `distanceKm` is left as 0.0
    // (documented limitation) and ranking happens in the use case layer.
    try {
      Query<Map<String, dynamic>> query = _firestoreService
          .collection(AppConfig.profilesCollection)
          .where('locality', isEqualTo: locality);
      if (requiredSkills.isNotEmpty) {
        query = query.where('skillsOffered', arrayContainsAny: requiredSkills);
      }

      final snapshot = await query.get();

      final candidates = <MatchCandidateDto>[];
      for (final doc in snapshot.docs) {
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

        final trustScore = await _firestoreService.getDocument<double>(
              collectionPath: AppConfig.trustScoresCollection,
              docId: doc.id,
              fromJson: (data) => (data['score'] as num).toDouble(),
            ) ??
            0.0;

        final candidate = MatchCandidate(
          userId: doc.id,
          profile: profileEntity,
          distanceKm: 0.0,
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
