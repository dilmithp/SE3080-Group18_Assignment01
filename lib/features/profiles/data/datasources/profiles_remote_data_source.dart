import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/error/exceptions.dart';
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

  /// Builds a [UserProfileDto] from a raw Firestore `profiles/{userId}`
  /// document. The document stores a native [GeoPoint] under `geoPoint`
  /// rather than the DTO's flat `latitude`/`longitude` fields, so we bypass
  /// [UserProfileDto.fromJson] and construct the DTO directly.
  UserProfileDto _dtoFromFirestore(String docId, Map<String, dynamic> data) {
    final geoPoint = data['geoPoint'] as GeoPoint;
    return UserProfileDto(
      userId: docId,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String,
      locality: data['locality'] as String,
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      skillsOffered: List<String>.from(data['skillsOffered'] as List),
      helpNeeded: List<String>.from(data['helpNeeded'] as List),
      availabilityWindows: List<Map<String, dynamic>>.from(
        (data['availabilityWindows'] as List)
            .map((window) => Map<String, dynamic>.from(window as Map)),
      ),
      accessibilityPrefs:
          Map<String, dynamic>.from(data['accessibilityPrefs'] as Map),
    );
  }

  /// Builds the Firestore-shaped map for a [UserProfileDto], replacing the
  /// DTO's flat `latitude`/`longitude` with a single native [GeoPoint].
  Map<String, dynamic> _firestoreDataFromDto(UserProfileDto dto) {
    final data = dto.toJson();
    data.remove('latitude');
    data.remove('longitude');
    data.remove('userId');
    data['geoPoint'] = GeoPoint(dto.latitude, dto.longitude);
    return data;
  }

  @override
  Future<UserProfileDto> getProfile(String userId) async {
    try {
      final dto = await _firestoreService.getDocument<UserProfileDto>(
        collectionPath: AppConfig.profilesCollection,
        docId: userId,
        fromJson: (json) => _dtoFromFirestore(userId, json),
      );
      if (dto == null) {
        throw const NotFoundException('Profile not found.');
      }
      return dto;
    } on NotFoundException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<UserProfileDto?> watchProfile(String userId) {
    return _firestoreService.watchDocument<UserProfileDto>(
      collectionPath: AppConfig.profilesCollection,
      docId: userId,
      fromJson: (json) => _dtoFromFirestore(userId, json),
    );
  }

  @override
  Future<UserProfileDto> updateProfile(UserProfileDto profile) async {
    try {
      await _firestoreService.setDocument(
        collectionPath: AppConfig.profilesCollection,
        docId: profile.userId,
        data: _firestoreDataFromDto(profile),
        merge: true,
      );
      return profile;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<String> uploadProfilePhoto({
    required String userId,
    required String filePath,
  }) async {
    try {
      final url = await _storageService.uploadFile(
        storagePath: '${AppConfig.profilePhotosPath}/$userId',
        file: File(filePath),
      );
      await _firestoreService.setDocument(
        collectionPath: AppConfig.profilesCollection,
        docId: userId,
        data: {'photoUrl': url},
        merge: true,
      );
      return url;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } catch (_) {
      throw const ServerException();
    }
  }
}
