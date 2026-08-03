import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/features/scheduling/data/models/session_dto.dart';
import 'package:elderly_companion/features/scheduling/data/models/session_feedback_dto.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';

/// Raw Firebase calls for scheduling — session booking/lifecycle and
/// feedback both live here even though they sit behind two separate
/// repository interfaces ([SessionRepository] / [FeedbackRepository])
/// above. Throws the exceptions in core/error/exceptions.dart; repository
/// implementations translate those into [Failure]s.
abstract class SchedulingRemoteDataSource {
  Future<SessionDto> bookSession({
    required String requesterId,
    required String volunteerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String location,
    String? notes,
  });

  Future<SessionDto> updateSessionStatus({
    required String sessionId,
    required SessionStatus status,
  });

  Future<SessionDto> getSession(String sessionId);

  Stream<List<SessionDto>> watchSessionsForUser(String userId);

  Future<SessionFeedbackDto> submitFeedback({
    required String sessionId,
    required String raterId,
    required int rating,
    String? comment,
  });

  Future<List<SessionFeedbackDto>> getFeedbackForSession(String sessionId);
}

class FirebaseSchedulingRemoteDataSource implements SchedulingRemoteDataSource {
  FirebaseSchedulingRemoteDataSource({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  @override
  Future<SessionDto> bookSession({
    required String requesterId,
    required String volunteerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String location,
    String? notes,
  }) async {
    try {
      final id = _firestoreService.newDocId(AppConfig.sessionsCollection);
      await _firestoreService.setDocument(
        collectionPath: AppConfig.sessionsCollection,
        docId: id,
        data: {
          'requesterId': requesterId,
          'volunteerId': volunteerId,
          'scheduledAt': Timestamp.fromDate(scheduledAt),
          'durationMinutes': durationMinutes,
          'status': SessionStatus.requested.name,
          'location': location,
          'notes': notes,
        },
      );
      return SessionDto(
        id: id,
        requesterId: requesterId,
        volunteerId: volunteerId,
        scheduledAtMillis: scheduledAt.millisecondsSinceEpoch,
        durationMinutes: durationMinutes,
        status: SessionStatus.requested.name,
        location: location,
        notes: notes,
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } on NotFoundException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<SessionDto> updateSessionStatus({
    required String sessionId,
    required SessionStatus status,
  }) async {
    try {
      final docRef =
          _firestoreService.collection(AppConfig.sessionsCollection).doc(sessionId);
      final existing = await docRef.get();
      if (existing.data() == null) {
        throw const NotFoundException('Session not found.');
      }
      await _firestoreService.setDocument(
        collectionPath: AppConfig.sessionsCollection,
        docId: sessionId,
        data: {'status': status.name},
      );
      return getSession(sessionId);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } on NotFoundException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<SessionDto> getSession(String sessionId) async {
    try {
      final snapshot = await _firestoreService
          .collection(AppConfig.sessionsCollection)
          .doc(sessionId)
          .get();
      final data = snapshot.data();
      if (data == null) {
        throw const NotFoundException('Session not found.');
      }
      return _sessionDtoFromData(sessionId, data);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } on NotFoundException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<List<SessionDto>> watchSessionsForUser(String userId) {
    return _firestoreService
        .collection(AppConfig.sessionsCollection)
        .where(
          Filter.or(
            Filter('requesterId', isEqualTo: userId),
            Filter('volunteerId', isEqualTo: userId),
          ),
        )
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => _sessionDtoFromData(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<SessionFeedbackDto> submitFeedback({
    required String sessionId,
    required String raterId,
    required int rating,
    String? comment,
  }) async {
    try {
      final id = _firestoreService.newDocId(AppConfig.sessionFeedbackCollection);
      final createdAt = Timestamp.now();
      await _firestoreService.setDocument(
        collectionPath: AppConfig.sessionFeedbackCollection,
        docId: id,
        data: {
          'sessionId': sessionId,
          'raterId': raterId,
          'rating': rating,
          'comment': comment,
          'createdAt': createdAt,
        },
      );
      return SessionFeedbackDto(
        sessionId: sessionId,
        raterId: raterId,
        rating: rating,
        comment: comment,
        createdAtMillis: createdAt.toDate().millisecondsSinceEpoch,
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } on NotFoundException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<List<SessionFeedbackDto>> getFeedbackForSession(String sessionId) async {
    try {
      return await _firestoreService.getCollection<SessionFeedbackDto>(
        collectionPath: AppConfig.sessionFeedbackCollection,
        queryBuilder: (query) => query.where('sessionId', isEqualTo: sessionId),
        fromJson: (data) => SessionFeedbackDto(
          sessionId: data['sessionId'] as String,
          raterId: data['raterId'] as String,
          rating: data['rating'] as int,
          comment: data['comment'] as String?,
          createdAtMillis:
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
        ),
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } on NotFoundException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  SessionDto _sessionDtoFromData(String id, Map<String, dynamic> data) {
    return SessionDto(
      id: id,
      requesterId: data['requesterId'] as String,
      volunteerId: data['volunteerId'] as String,
      scheduledAtMillis: (data['scheduledAt'] as Timestamp).millisecondsSinceEpoch,
      durationMinutes: data['durationMinutes'] as int,
      status: data['status'] as String,
      location: data['location'] as String,
      notes: data['notes'] as String?,
    );
  }
}
