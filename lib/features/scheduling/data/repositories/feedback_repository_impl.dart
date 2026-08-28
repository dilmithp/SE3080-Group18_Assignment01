import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/notifications/domain/entities/notification_type.dart';
import 'package:elderly_companion/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:elderly_companion/features/scheduling/data/datasources/scheduling_remote_data_source.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_feedback.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/feedback_repository.dart';

/// Satisfies [FeedbackRepository]. Every method is stubbed — see
/// SessionRepositoryImpl for the pattern to follow when implementing.
class FeedbackRepositoryImpl implements FeedbackRepository {
  const FeedbackRepositoryImpl(this._dataSource, [this._notificationsRepository]);

  final SchedulingRemoteDataSource _dataSource;

  /// Optional so this constructor stays backward-compatible with the
  /// current `FeedbackRepositoryImpl(dataSource)` call site in
  /// scheduling_providers.dart (outside this change's file boundary — see
  /// this feature's report for the wiring snippet that pass needs to apply
  /// there). `null` just means the best-effort notification below is
  /// skipped, never a crash.
  final NotificationsRepository? _notificationsRepository;

  @override
  Future<Either<Failure, SessionFeedback>> submitFeedback({
    required String sessionId,
    required String raterId,
    required int rating,
    String? comment,
  }) async {
    try {
      final dto = await _dataSource.submitFeedback(
        sessionId: sessionId,
        raterId: raterId,
        rating: rating,
        comment: comment,
      );
      final feedback = dto.toEntity();
      await _notifyFeedbackReceived(sessionId: sessionId, raterId: raterId);
      return Right(feedback);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<SessionFeedback>>> getFeedbackForSession(
    String sessionId,
  ) async {
    try {
      final dtos = await _dataSource.getFeedbackForSession(sessionId);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  /// Best-effort notification side effect of a successful feedback
  /// submission, for whichever session participant did *not* leave the
  /// rating. Wrapped in its own try/catch — deliberately not left to the
  /// caller's try/catch in [submitFeedback] — so a failure here (including
  /// the extra `getSession` read needed to resolve the other participant)
  /// is swallowed rather than turning an already-successful feedback write
  /// into a reported failure.
  Future<void> _notifyFeedbackReceived({
    required String sessionId,
    required String raterId,
  }) async {
    final repo = _notificationsRepository;
    if (repo == null) return;

    try {
      final session = await _dataSource.getSession(sessionId);
      final recipientId = session.requesterId == raterId
          ? session.volunteerId
          : session.requesterId;

      await repo.createNotification(
        userId: recipientId,
        type: NotificationType.feedbackReceived,
        title: 'New feedback received',
        body: 'You received new feedback for a recent session.',
        relatedId: sessionId,
      );
    } catch (_) {
      // Best-effort — see doc comment above.
    }
  }
}
