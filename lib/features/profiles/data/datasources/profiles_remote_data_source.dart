import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/core/services/storage_service.dart';
import 'package:elderly_companion/features/profiles/data/models/user_profile_dto.dart';

/// Raw Firebase calls for profiles — the only place in this feature allowed
/// to talk to Firestore/Storage (via the core service wrappers). Throws the
/// exceptions in core/error/exceptions.dart; repository implementations
/// translate those into [Failure]s.
abstract class ProfilesRemoteDataSource {
  Future<UserProfileDto> getProfile(String userId);

  Stream<UserProfileDto?> watchProfile(String userId);

  Future<UserProfileDto> updateProfile(UserProfileDto profile);

  Future<String> uploadProfilePhoto({
    required String userId,
    required String filePath,
  });
}

class FirebaseProfilesRemoteDataSource implements ProfilesRemoteDataSource {
  FirebaseProfilesRemoteDataSource({
    required FirestoreService firestoreService,
    required StorageService storageService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService;

  final FirestoreService _firestoreService;
  final StorageService _storageService;

  @override
  Future<UserProfileDto> getProfile(String userId) async {
    throw UnimplementedError(
      'TODO(Perera): read ${AppConfig.profilesCollection} via $_firestoreService',
    );
  }

  @override
  Stream<UserProfileDto?> watchProfile(String userId) {
    throw UnimplementedError(
      'TODO(Perera): watch ${AppConfig.profilesCollection} via $_firestoreService',
    );
  }

  @override
  Future<UserProfileDto> updateProfile(UserProfileDto profile) async {
    throw UnimplementedError(
      'TODO(Perera): write to ${AppConfig.profilesCollection} via $_firestoreService',
    );
  }

  @override
  Future<String> uploadProfilePhoto({
    required String userId,
    required String filePath,
  }) async {
    throw UnimplementedError(
      'TODO(Perera): upload $filePath to ${AppConfig.profilePhotosPath} via '
      '$_storageService, then write the resulting URL to the profile doc via '
      '$_firestoreService',
    );
  }
}
