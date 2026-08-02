import 'package:elderly_companion/core/config/app_config.dart';
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
    throw UnimplementedError(
      'TODO(Ranketh): write a new doc to ${AppConfig.sessionsCollection} '
      'via $_firestoreService',
    );
  }

  @override
  Future<SessionDto> updateSessionStatus({
    required String sessionId,
    required SessionStatus status,
  }) async {
    throw UnimplementedError(
      'TODO(Ranketh): update the ${AppConfig.sessionsCollection} doc via '
      '$_firestoreService',
    );
  }

  @override
  Future<SessionDto> getSession(String sessionId) async {
    throw UnimplementedError(
      'TODO(Ranketh): read ${AppConfig.sessionsCollection} via $_firestoreService',
    );
  }

  @override
  Stream<List<SessionDto>> watchSessionsForUser(String userId) {
    throw UnimplementedError(
      'TODO(Ranketh): watch ${AppConfig.sessionsCollection} (requesterId or '
      'volunteerId == userId) via $_firestoreService',
    );
  }

  @override
  Future<SessionFeedbackDto> submitFeedback({
    required String sessionId,
    required String raterId,
    required int rating,
    String? comment,
  }) async {
    throw UnimplementedError(
      'TODO(Ranketh): write a new doc to ${AppConfig.sessionFeedbackCollection} '
      'via $_firestoreService',
    );
  }

  @override
  Future<List<SessionFeedbackDto>> getFeedbackForSession(String sessionId) async {
    throw UnimplementedError(
      'TODO(Ranketh): read ${AppConfig.sessionFeedbackCollection} via '
      '$_firestoreService',
    );
  }
}
