import 'package:firebase_auth/firebase_auth.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/features/auth_trust/data/models/app_user_dto.dart';
import 'package:elderly_companion/features/auth_trust/data/models/trust_score_dto.dart';
import 'package:elderly_companion/features/auth_trust/data/models/verification_request_dto.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';

/// Raw Firebase calls for auth_trust — the only place in this feature
/// allowed to import `firebase_auth`. Throws the exceptions in
/// core/error/exceptions.dart; repository implementations translate those
/// into [Failure]s.
abstract class AuthTrustRemoteDataSource {
  Future<AppUserDto> signUpWithEmail({
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  });

  Future<AppUserDto> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Stream<AppUserDto?> authStateChanges();

  Future<VerificationRequestDto> submitVerificationRequest({
    required String userId,
    required String documentUrl,
  });

  Stream<VerificationRequestDto?> watchVerificationStatus(String userId);

  Future<VerificationRequestDto> reviewVerificationRequest({
    required String requestId,
    required String reviewerId,
    required bool approve,
  });

  Future<TrustScoreDto> getTrustScore(String userId);

  Stream<TrustScoreDto?> watchTrustScore(String userId);
}

class FirebaseAuthTrustRemoteDataSource implements AuthTrustRemoteDataSource {
  FirebaseAuthTrustRemoteDataSource({
    required FirebaseAuth firebaseAuth,
    required FirestoreService firestoreService,
  })  : _firebaseAuth = firebaseAuth,
        _firestoreService = firestoreService;

  final FirebaseAuth _firebaseAuth;
  final FirestoreService _firestoreService;

  @override
  Future<AppUserDto> signUpWithEmail({
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    throw UnimplementedError(
      'TODO(Pathirana): create FirebaseAuth user, then write the profile '
      'doc to ${AppConfig.usersCollection} via $_firebaseAuth / $_firestoreService',
    );
  }

  @override
  Future<AppUserDto> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError(
      'TODO(Pathirana): sign in via $_firebaseAuth and fetch the matching '
      '${AppConfig.usersCollection} doc via $_firestoreService',
    );
  }

  @override
  Future<void> signOut() async {
    throw UnimplementedError('TODO(Pathirana): implement via $_firebaseAuth');
  }

  @override
  Stream<AppUserDto?> authStateChanges() {
    throw UnimplementedError(
      'TODO(Pathirana): map $_firebaseAuth.authStateChanges() to '
      '${AppConfig.usersCollection} doc reads via $_firestoreService',
    );
  }

  @override
  Future<VerificationRequestDto> submitVerificationRequest({
    required String userId,
    required String documentUrl,
  }) async {
    throw UnimplementedError(
      'TODO(Pathirana): write to ${AppConfig.verificationRequestsCollection} '
      'via $_firestoreService',
    );
  }

  @override
  Stream<VerificationRequestDto?> watchVerificationStatus(String userId) {
    throw UnimplementedError(
      'TODO(Pathirana): watch ${AppConfig.verificationRequestsCollection} '
      'via $_firestoreService',
    );
  }

  @override
  Future<VerificationRequestDto> reviewVerificationRequest({
    required String requestId,
    required String reviewerId,
    required bool approve,
  }) async {
    throw UnimplementedError(
      'TODO(Pathirana): update ${AppConfig.verificationRequestsCollection} '
      'via $_firestoreService — admin-only, enforce via firestore.rules',
    );
  }

  @override
  Future<TrustScoreDto> getTrustScore(String userId) async {
    throw UnimplementedError(
      'TODO(Pathirana): read ${AppConfig.trustScoresCollection} via $_firestoreService',
    );
  }

  @override
  Stream<TrustScoreDto?> watchTrustScore(String userId) {
    throw UnimplementedError(
      'TODO(Pathirana): watch ${AppConfig.trustScoresCollection} via $_firestoreService',
    );
  }
}
