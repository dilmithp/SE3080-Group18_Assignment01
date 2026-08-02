import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/features/matching/data/models/match_candidate_dto.dart';

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
    // A real implementation would likely query AppConfig.profilesCollection
    // for locality/skill filters via $_firestoreService, then either compute
    // distanceKm client-side from geoPoint or call a Cloud Function to do
    // the geo-distance + ranking work server-side before returning DTOs.
    throw UnimplementedError(
      'TODO(Wijekoon): query ${AppConfig.profilesCollection} via '
      '$_firestoreService (locality/skill filters, geo-distance calculation '
      'possibly via a Cloud Function)',
    );
  }
}
