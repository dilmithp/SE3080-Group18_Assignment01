import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/features/scheduling/data/exceptions/scheduling_exceptions.dart';
import 'package:elderly_companion/features/scheduling/data/models/session_dto.dart';
import 'package:elderly_companion/features/scheduling/data/models/session_feedback_dto.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/services/session_conflict_detector.dart';

/// Raw Firebase calls for scheduling — session booking/lifecycle and
/// feedback both live here even though they sit behind two separate
/// repository interfaces ([SessionRepository] / [FeedbackRepository])
/// above. Throws the exceptions in core/error/exceptions.dart; repository
/// implementations translate those into [Failure]s.
abstract class SchedulingRemoteDataSource {
  /// Writes one `requested` session.
  ///
  /// The recurrence arguments describe the series this session belongs to,
  /// if any; they are written as given and interpreted nowhere in this
  /// layer. A one-off booking leaves all three at their defaults.
  Future<SessionDto> bookSession({
    required String requesterId,
    required String volunteerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String location,
    String? notes,
    bool isRecurring = false,
    String? recurrenceRule,
    String? seriesId,
  });

  Future<SessionDto> updateSessionStatus({
    required String sessionId,
    required SessionStatus status,
  });

  /// Accepts [sessionId] on behalf of [confirmingUserId], re-checking the
  /// slot inside a Firestore transaction. Throws
  /// [SessionConflictException] if the slot was taken in the meantime and
  /// [InvalidSessionTransitionException] if the session is no longer in a
  /// state that can be confirmed.
  Future<SessionDto> confirmSession({
    required String sessionId,
    required String confirmingUserId,
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
  FirebaseSchedulingRemoteDataSource({
    required FirestoreService firestoreService,
    SessionConflictDetector conflictDetector = const SessionConflictDetector(),
  })  : _firestoreService = firestoreService,
        _conflictDetector = conflictDetector;

  final FirestoreService _firestoreService;
  final SessionConflictDetector _conflictDetector;

  @override
  Future<SessionDto> bookSession({
    required String requesterId,
    required String volunteerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String location,
    String? notes,
    bool isRecurring = false,
    String? recurrenceRule,
    String? seriesId,
  }) async {
    try {
      final id = _firestoreService.newDocId(AppConfig.sessionsCollection);
      // Client clock rather than FieldValue.serverTimestamp() so the DTO
      // returned below matches what was just written without a second read.
      // TODO(ranketh): switch the audit stamps to serverTimestamp() once
      // something actually orders sessions by them — a skewed device clock
      // matters for sorting, not for the display this feeds today.
      final now = Timestamp.now();
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
          // Unflagged until something detects an overlap that could not be
          // seen at request time.
          'isRecurring': isRecurring,
          'recurrenceRule': recurrenceRule,
          'seriesId': seriesId,
          'conflictFlag': false,
          'createdAt': now,
          'updatedAt': now,
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
        isRecurring: isRecurring,
        recurrenceRule: recurrenceRule,
        seriesId: seriesId,
        createdAtMillis: now.millisecondsSinceEpoch,
        updatedAtMillis: now.millisecondsSinceEpoch,
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
        data: {'status': status.name, 'updatedAt': Timestamp.now()},
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
  Future<SessionDto> confirmSession({
    required String sessionId,
    required String confirmingUserId,
  }) async {
    try {
      final collection =
          _firestoreService.collection(AppConfig.sessionsCollection);
      final sessionRef = collection.doc(sessionId);

      // Read once up front to learn who and when — the shortlist query below
      // needs the session's own time window, and the transaction re-reads
      // this same document anyway before trusting anything here.
      final preRead = await sessionRef.get();
      final preReadData = preRead.data();
      if (preReadData == null) {
        throw const NotFoundException('Session not found.');
      }
      final candidate = _sessionDtoFromData(sessionId, preReadData).toEntity();

      // The client SDK cannot run a query inside a transaction, so the
      // possible clashes are shortlisted here and each one is then re-read
      // *by reference* inside the transaction — that puts them in the
      // transaction's read set, so a concurrent write to any of them aborts
      // and retries this whole block rather than confirming over the top of
      // it.
      //
      // Only the confirming user's own sessions are visible: firestore.rules
      // restricts `sessions` reads to that document's own participants, so a
      // query spanning the counterparty's other bookings would be rejected.
      // TODO(ranketh): the counterparty's side of the calendar can only be
      // checked with the Admin SDK — move this check into the reminders
      // Cloud Function when backend/ is in scope.
      final shortlist = await collection
          .where(
            Filter.or(
              Filter('requesterId', isEqualTo: confirmingUserId),
              Filter('volunteerId', isEqualTo: confirmingUserId),
            ),
          )
          .get();

      final refs = shortlist.docs
          .where((doc) => doc.id != sessionId)
          .where(
            (doc) => _conflictDetector.hasConflict(
              candidate: candidate,
              existing: [_sessionDtoFromData(doc.id, doc.data()).toEntity()],
            ),
          )
          .map((doc) => doc.reference)
          .toList();

      return await sessionRef.firestore.runTransaction<SessionDto>((txn) async {
        // Every read has to happen before the first write in a transaction,
        // hence the two loops.
        final snapshot = await txn.get(sessionRef);
        final data = snapshot.data();
        if (data == null) {
          throw const NotFoundException('Session not found.');
        }
        final current = _sessionDtoFromData(sessionId, data).toEntity();

        if (!current.status.canTransitionTo(SessionStatus.confirmed)) {
          throw InvalidSessionTransitionException(
            'This session is ${current.status.label.toLowerCase()} and can no '
            'longer be confirmed.',
          );
        }

        final others = <Session>[];
        for (final ref in refs) {
          final otherSnapshot = await txn.get(ref);
          final otherData = otherSnapshot.data();
          if (otherData == null) continue;
          others.add(_sessionDtoFromData(otherSnapshot.id, otherData).toEntity());
        }

        final conflicts = _conflictDetector.conflictsFor(
          candidate: current,
          existing: others,
        );
        if (conflicts.isNotEmpty) {
          throw const SessionConflictException();
        }

        final confirmedAt = Timestamp.now();
        txn.update(sessionRef, {
          'status': SessionStatus.confirmed.name,
          'updatedAt': confirmedAt,
        });
        return SessionDto.fromEntity(
          current.copyWith(
            status: SessionStatus.confirmed,
            updatedAt: confirmedAt.toDate(),
          ),
        );
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } on SessionConflictException {
      rethrow;
    } on InvalidSessionTransitionException {
      rethrow;
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
      // Every lifecycle field is read defensively: sessions booked before
      // these keys existed have none of them, and those documents must
      // still read back cleanly rather than throwing a cast error.
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurrenceRule: data['recurrenceRule'] as String?,
      checkInAtMillis: (data['checkInAt'] as Timestamp?)?.millisecondsSinceEpoch,
      checkOutAtMillis: (data['checkOutAt'] as Timestamp?)?.millisecondsSinceEpoch,
      conflictFlag: data['conflictFlag'] as bool? ?? false,
      seriesId: data['seriesId'] as String?,
      createdAtMillis: (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch,
      updatedAtMillis: (data['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch,
    );
  }
}
