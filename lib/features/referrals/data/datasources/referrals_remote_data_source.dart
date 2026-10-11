import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/features/referrals/data/models/referral_code_dto.dart';
import 'package:elderly_companion/features/referrals/data/models/referral_dto.dart';

/// Firestore collection names for the referral program. Not in
/// `core/config/app_config.dart`'s `AppConfig` because this feature's file
/// set is standalone (see the ownership note in docs/DATA_MODEL.md, same as
/// `community`) — kept local to this data source the same way a rename
/// would only ever touch this one file.
const String _referralCodesCollection = 'referral_codes';
const String _referralsCollection = 'referrals';

/// Characters a code is drawn from — upper-case letters and digits, minus
/// the pairs people most often misread off a screen (0/O, 1/I).
const String _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const int _codeLength = 6;
const int _maxGenerationAttempts = 5;

/// Raw Firebase calls for the referral program. Throws the exceptions in
/// core/error/exceptions.dart; [ReferralRepositoryImpl] translates those
/// into [Failure]s.
abstract class ReferralsRemoteDataSource {
  /// [userId]'s existing code, or a freshly generated and persisted one if
  /// they don't have one yet.
  Future<ReferralCodeDto> getOrCreateCode(String userId);

  /// Redeems [code] for [referredUserId]. Throws [NotFoundException] if
  /// [code] doesn't exist, and [PermissionException] if [referredUserId] is
  /// the code's own owner or has already redeemed a code before — the
  /// authoritative checks still live in firestore.rules, this is a
  /// client-side fast-fail so the UI can show a clear message rather than a
  /// raw Firestore permission error.
  Future<ReferralDto> redeemCode({
    required String code,
    required String referredUserId,
    required String referredName,
  });

  Future<bool> hasRedeemedCode(String userId);

  /// Everyone [referrerId] has referred, newest first.
  Stream<List<ReferralDto>> watchMyReferrals(String referrerId);
}

class FirebaseReferralsRemoteDataSource implements ReferralsRemoteDataSource {
  FirebaseReferralsRemoteDataSource({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;
  final Random _random = Random.secure();

  String _generateCandidateCode() {
    return List.generate(
      _codeLength,
      (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
    ).join();
  }

  @override
  Future<ReferralCodeDto> getOrCreateCode(String userId) async {
    try {
      final existing = await _firestoreService
          .collection(_referralCodesCollection)
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return _codeDtoFromData(existing.docs.first.id, existing.docs.first.data());
      }

      for (var attempt = 0; attempt < _maxGenerationAttempts; attempt++) {
        final candidate = _generateCandidateCode();
        final docRef = _firestoreService.collection(_referralCodesCollection).doc(candidate);
        final snapshot = await docRef.get();
        if (snapshot.exists) continue;

        final now = Timestamp.now();
        await docRef.set({'ownerId': userId, 'createdAt': now});
        return ReferralCodeDto(
          code: candidate,
          ownerId: userId,
          createdAtMillis: now.millisecondsSinceEpoch,
        );
      }
      throw const ServerException('Could not generate a unique referral code.');
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<ReferralDto> redeemCode({
    required String code,
    required String referredUserId,
    required String referredName,
  }) async {
    try {
      final normalizedCode = code.trim().toUpperCase();
      final codeSnapshot =
          await _firestoreService.collection(_referralCodesCollection).doc(normalizedCode).get();
      final codeData = codeSnapshot.data();
      if (codeData == null) {
        throw const NotFoundException('That referral code is not valid.');
      }
      final referrerId = codeData['ownerId'] as String;
      if (referrerId == referredUserId) {
        throw const PermissionException('You cannot redeem your own referral code.');
      }

      // Doc ID = referredUserId, so a second redemption attempt lands on an
      // existing doc — Firestore (and firestore.rules, which denies every
      // update) treats that as an update rather than a create, which is
      // what actually makes "at most one redemption per user" atomic rather
      // than a racy read-then-write check.
      final docRef = _firestoreService.collection(_referralsCollection).doc(referredUserId);
      final existing = await docRef.get();
      if (existing.exists) {
        throw const PermissionException('You have already used a referral code.');
      }

      final now = Timestamp.now();
      await docRef.set({
        'code': normalizedCode,
        'referrerId': referrerId,
        'referredUserId': referredUserId,
        'referredName': referredName,
        'createdAt': now,
      });
      return ReferralDto(
        id: referredUserId,
        code: normalizedCode,
        referrerId: referrerId,
        referredUserId: referredUserId,
        referredName: referredName,
        createdAtMillis: now.millisecondsSinceEpoch,
      );
    } on NotFoundException {
      rethrow;
    } on PermissionException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<bool> hasRedeemedCode(String userId) async {
    try {
      final snapshot =
          await _firestoreService.collection(_referralsCollection).doc(userId).get();
      return snapshot.exists;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<List<ReferralDto>> watchMyReferrals(String referrerId) {
    return _firestoreService
        .collection(_referralsCollection)
        .where('referrerId', isEqualTo: referrerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _referralDtoFromData(doc.id, doc.data())).toList(),
        );
  }

  ReferralCodeDto _codeDtoFromData(String code, Map<String, dynamic> data) {
    return ReferralCodeDto(
      code: code,
      ownerId: data['ownerId'] as String,
      createdAtMillis: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
    );
  }

  ReferralDto _referralDtoFromData(String id, Map<String, dynamic> data) {
    return ReferralDto(
      id: id,
      code: data['code'] as String,
      referrerId: data['referrerId'] as String,
      referredUserId: data['referredUserId'] as String,
      referredName: data['referredName'] as String,
      createdAtMillis: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
    );
  }
}
