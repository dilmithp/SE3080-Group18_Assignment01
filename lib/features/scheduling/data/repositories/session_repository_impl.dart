import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/notifications/domain/entities/notification_type.dart';
import 'package:elderly_companion/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:elderly_companion/features/scheduling/data/datasources/scheduling_remote_data_source.dart';
import 'package:elderly_companion/features/scheduling/data/exceptions/scheduling_exceptions.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';

/// Satisfies [SessionRepository]. Every method is stubbed — the job of
/// implementing this class is to call [_dataSource], catch the exceptions
/// in core/error/exceptions.dart, and map them to a [Failure].
class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._dataSource, [this._notificationsRepository]);

  final SchedulingRemoteDataSource _dataSource;

  /// Optional so this constructor stays backward-compatible with the
  /// current `SessionRepositoryImpl(dataSource)` call site in
  /// scheduling_providers.dart (outside this change's file boundary — see
  /// this feature's report for the exact wiring snippet that pass needs to
  /// apply there). Every notification send below is best-effort and never
  /// allowed to fail the underlying status change, so a `null` here simply
  /// means "no notification sent" rather than a crash.
  final NotificationsRepository? _notificationsRepository;

  @override
  Future<Either<Failure, Session>> bookSession({
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
      final dto = await _dataSource.bookSession(
        requesterId: requesterId,
        volunteerId: volunteerId,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        location: location,
        notes: notes,
        isRecurring: isRecurring,
        recurrenceRule: recurrenceRule,
        seriesId: seriesId,
      );
      return Right(dto.toEntity());
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
  Future<Either<Failure, Session>> updateSessionStatus({
    required String sessionId,
    required SessionStatus status,
  }) async {
    try {
      final dto = await _dataSource.updateSessionStatus(
        sessionId: sessionId,
        status: status,
      );
      final session = dto.toEntity();
      // Best-effort: no actor is threaded through this generic status
      // write (unlike confirmSession below, which takes one), so both
      // participants are notified rather than guessing who acted — see
      // the `_notificationsRepository` doc comment above.
      await _notifyStatusChange(session: session, status: status);
      return Right(session);
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
  Future<Either<Failure, Session>> confirmSession({
    required String sessionId,
    required String confirmingUserId,
  }) async {
    try {
      final dto = await _dataSource.confirmSession(
        sessionId: sessionId,
        confirmingUserId: confirmingUserId,
      );
      final session = dto.toEntity();
      // confirmSession does know its actor, so — unlike updateSessionStatus
      // above — only the other participant gets notified here.
      await _notifyStatusChange(
        session: session,
        status: SessionStatus.confirmed,
        actingUserId: confirmingUserId,
      );
      return Right(session);
    } on SessionConflictException catch (e) {
      // TODO(ranketh): a dedicated ConflictFailure belongs in
      // core/error/failures.dart so callers can branch on the type instead
      // of reading the message — Failure is sealed, so it cannot be
      // subclassed from this feature. Needs the two-reviewer process for
      // core changes.
      return Left(UnknownFailure(e.message));
    } on InvalidSessionTransitionException catch (e) {
      return Left(UnknownFailure(e.message));
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
  Future<Either<Failure, Session>> getSession(String sessionId) async {
    try {
      final dto = await _dataSource.getSession(sessionId);
      return Right(dto.toEntity());
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
  Stream<List<Session>> watchSessionsForUser(String userId) {
    return _dataSource
        .watchSessionsForUser(userId)
        .map((dtos) => dtos.map((d) => d.toEntity()).toList());
  }

  /// Best-effort notification side effect of a status change. Never throws
  /// — a failure here must not surface as a failure of the status write
  /// that triggered it, so every send is individually wrapped.
  ///
  /// When [actingUserId] is known (confirmSession), only the other
  /// participant is notified. When it isn't (the generic
  /// updateSessionStatus path has no actor to exclude), both participants
  /// are notified — see the doc comment on [_notificationsRepository].
  Future<void> _notifyStatusChange({
    required Session session,
    required SessionStatus status,
    String? actingUserId,
  }) async {
    final repo = _notificationsRepository;
    if (repo == null) return;

    final content = _notificationContentFor(status);
    if (content == null) return;

    final when = DateFormat('EEE, d MMM · h:mm a').format(session.scheduledAt);
    final participants = {session.requesterId, session.volunteerId};
    final recipients = actingUserId == null
        ? participants
        : participants.where((id) => id != actingUserId).toSet();

    for (final recipientId in recipients) {
      try {
        await repo.createNotification(
          userId: recipientId,
          type: content.type,
          title: content.title,
          body: '${content.bodyPrefix} $when.',
          relatedId: session.id,
        );
      } catch (_) {
        // Best-effort — see doc comment above.
      }
    }
  }

  ({NotificationType type, String title, String bodyPrefix})? _notificationContentFor(
    SessionStatus status,
  ) {
    switch (status) {
      case SessionStatus.confirmed:
        return (
          type: NotificationType.sessionConfirmed,
          title: 'Session confirmed',
          bodyPrefix: 'Your session on',
        );
      case SessionStatus.cancelled:
        return (
          type: NotificationType.sessionCancelled,
          title: 'Session cancelled',
          bodyPrefix: 'Your session on',
        );
      case SessionStatus.completed:
        return (
          type: NotificationType.sessionCompleted,
          title: 'Session completed',
          bodyPrefix: 'Your session on',
        );
      case SessionStatus.requested:
        // Booking a session already has its own UI feedback for the
        // requester; nothing new to tell the volunteer here beyond what
        // sessionsForUserProvider already streams to their session list.
        return null;
    }
  }
}
