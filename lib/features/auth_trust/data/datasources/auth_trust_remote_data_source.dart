import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/error/exceptions.dart';
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

  /// Admin-only: every request currently `status == 'pending'`, across all
  /// users.
  Stream<List<VerificationRequestDto>> watchPendingVerificationRequests();

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

  AppUserDto _appUserDtoFromData(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'] as Timestamp;
    return AppUserDto(
      id: id,
      email: data['email'] as String,
      phone: data['phone'] as String,
      role: data['role'] as String,
      isVerified: data['isVerified'] as bool,
      createdAtMillis: createdAt.millisecondsSinceEpoch,
    );
  }

  VerificationRequestDto _verificationRequestDtoFromData(
    String id,
    Map<String, dynamic> data,
  ) {
    final reviewedAt = data['reviewedAt'] as Timestamp?;
    return VerificationRequestDto(
      id: id,
      userId: data['userId'] as String,
      documentUrl: data['documentUrl'] as String,
      status: data['status'] as String,
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAtMillis: reviewedAt?.millisecondsSinceEpoch,
    );
  }

  TrustScoreDto _trustScoreDtoFromData(String userId, Map<String, dynamic> data) {
    final lastUpdated = data['lastUpdated'] as Timestamp;
    return TrustScoreDto(
      userId: userId,
      score: (data['score'] as num).toDouble(),
      completedSessions: data['completedSessions'] as int,
      averageRating: (data['averageRating'] as num).toDouble(),
      lastUpdatedMillis: lastUpdated.millisecondsSinceEpoch,
    );
  }

  @override
  Future<AppUserDto> signUpWithEmail({
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final now = Timestamp.now();
      await _firestoreService.setDocument(
        collectionPath: AppConfig.usersCollection,
        docId: uid,
        data: {
          'email': email,
          'phone': phone,
          'role': role.name,
          'isVerified': false,
          'createdAt': now,
        },
      );
      return AppUserDto(
        id: uid,
        email: email,
        phone: phone,
        role: role.name,
        isVerified: false,
        createdAtMillis: now.millisecondsSinceEpoch,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign-up failed.');
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<AppUserDto> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final dto = await _firestoreService.getDocument(
        collectionPath: AppConfig.usersCollection,
        docId: uid,
        fromJson: (data) => _appUserDtoFromData(uid, data),
      );
      if (dto == null) {
        throw const NotFoundException('User profile not found.');
      }
      return dto;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign-in failed.');
    } on NotFoundException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<AppUserDto?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _firestoreService.getDocument(
        collectionPath: AppConfig.usersCollection,
        docId: user.uid,
        fromJson: (data) => _appUserDtoFromData(user.uid, data),
      );
    });
  }

  @override
  Future<VerificationRequestDto> submitVerificationRequest({
    required String userId,
    required String documentUrl,
  }) async {
    try {
      final id = _firestoreService.newDocId(
        AppConfig.verificationRequestsCollection,
      );
      await _firestoreService.setDocument(
        collectionPath: AppConfig.verificationRequestsCollection,
        docId: id,
        data: {
          'userId': userId,
          'documentUrl': documentUrl,
          'status': 'pending',
        },
      );
      return VerificationRequestDto(
        id: id,
        userId: userId,
        documentUrl: documentUrl,
        status: 'pending',
      );
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<VerificationRequestDto?> watchVerificationStatus(String userId) {
    return _firestoreService
        .collection(AppConfig.verificationRequestsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return _verificationRequestDtoFromData(doc.id, doc.data());
    });
  }

  @override
  Stream<List<VerificationRequestDto>> watchPendingVerificationRequests() {
    return _firestoreService
        .collection(AppConfig.verificationRequestsCollection)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _verificationRequestDtoFromData(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<VerificationRequestDto> reviewVerificationRequest({
    required String requestId,
    required String reviewerId,
    required bool approve,
  }) async {
    try {
      final docRef = _firestoreService
          .collection(AppConfig.verificationRequestsCollection)
          .doc(requestId);
      final snapshot = await docRef.get();
      final data = snapshot.data();
      if (data == null) {
        throw const NotFoundException('Verification request not found.');
      }
      final userId = data['userId'] as String;
      final reviewedAt = Timestamp.now();
      final status = approve ? 'approved' : 'rejected';
      await docRef.set(
        {
          'status': status,
          'reviewedBy': reviewerId,
          'reviewedAt': reviewedAt,
        },
        SetOptions(merge: true),
      );
      if (approve) {
        await _firestoreService.setDocument(
          collectionPath: AppConfig.usersCollection,
          docId: userId,
          data: {'isVerified': true},
        );
      }
      return VerificationRequestDto(
        id: requestId,
        userId: userId,
        documentUrl: data['documentUrl'] as String,
        status: status,
        reviewedBy: reviewerId,
        reviewedAtMillis: reviewedAt.millisecondsSinceEpoch,
      );
    } on NotFoundException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<TrustScoreDto> getTrustScore(String userId) async {
    try {
      final dto = await _firestoreService.getDocument(
        collectionPath: AppConfig.trustScoresCollection,
        docId: userId,
        fromJson: (data) => _trustScoreDtoFromData(userId, data),
      );
      if (dto == null) {
        throw const NotFoundException('Trust score not found.');
      }
      return dto;
    } on NotFoundException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<TrustScoreDto?> watchTrustScore(String userId) {
    return _firestoreService.watchDocument(
      collectionPath: AppConfig.trustScoresCollection,
      docId: userId,
      fromJson: (data) => _trustScoreDtoFromData(userId, data),
    );
  }
}
