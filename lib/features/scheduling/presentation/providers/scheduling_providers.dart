import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:elderly_companion/features/scheduling/data/datasources/scheduling_remote_data_source.dart';
import 'package:elderly_companion/features/scheduling/data/repositories/feedback_repository_impl.dart';
import 'package:elderly_companion/features/scheduling/data/repositories/session_repository_impl.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_feedback.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/feedback_repository.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';
import 'package:elderly_companion/features/scheduling/domain/services/session_series.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/book_recurring_session_usecase.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/book_session_usecase.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/cancel_series_usecase.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/confirm_session_usecase.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/submit_feedback_usecase.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/update_session_status_usecase.dart';

/// All Dependency-Inversion wiring for scheduling lives here: presentation
/// and domain depend only on the abstract repository interfaces above;
/// this file is the only place that knows [SessionRepositoryImpl] etc.
/// exist.

final schedulingRemoteDataSourceProvider = Provider<SchedulingRemoteDataSource>((ref) {
  return FirebaseSchedulingRemoteDataSource(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(
    ref.watch(schedulingRemoteDataSourceProvider),
    ref.watch(notificationsRepositoryProvider),
  );
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepositoryImpl(
    ref.watch(schedulingRemoteDataSourceProvider),
    ref.watch(notificationsRepositoryProvider),
  );
});

final bookSessionUseCaseProvider = Provider<BookSessionUseCase>((ref) {
  return BookSessionUseCase(ref.watch(sessionRepositoryProvider));
});

/// Not reachable from any screen yet — the recurring-booking UI is a
/// separate piece of work; this is here so the wiring is in one place when
/// it lands.
final bookRecurringSessionUseCaseProvider =
    Provider<BookRecurringSessionUseCase>((ref) {
  return BookRecurringSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final cancelSeriesUseCaseProvider = Provider<CancelSeriesUseCase>((ref) {
  return CancelSeriesUseCase(ref.watch(sessionRepositoryProvider));
});

final confirmSessionUseCaseProvider = Provider<ConfirmSessionUseCase>((ref) {
  return ConfirmSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final updateSessionStatusUseCaseProvider = Provider<UpdateSessionStatusUseCase>((ref) {
  return UpdateSessionStatusUseCase(ref.watch(sessionRepositoryProvider));
});

final submitFeedbackUseCaseProvider = Provider<SubmitFeedbackUseCase>((ref) {
  return SubmitFeedbackUseCase(ref.watch(feedbackRepositoryProvider));
});

/// Live list of sessions (as requester or volunteer) for a user.
final sessionsForUserProvider =
    StreamProvider.family<List<Session>, String>((ref, userId) {
  return ref.watch(sessionRepositoryProvider).watchSessionsForUser(userId);
});

/// Every occurrence of one recurring series, earliest first.
///
/// Derived from [sessionsForUserProvider] rather than querying Firestore
/// again: that stream already carries every session the user is on, so a
/// series is a filter over data in hand — no second read, and no composite
/// index for a `seriesId` query that nobody has created.
final sessionSeriesProvider = Provider.family<AsyncValue<List<Session>>,
    ({String userId, String seriesId})>((ref, args) {
  return ref.watch(sessionsForUserProvider(args.userId)).whenData(
        (sessions) => const SessionSeries()
            .occurrencesOf(seriesId: args.seriesId, sessions: sessions),
      );
});

/// Feedback already recorded against a session. Folds the [Failure] into an
/// error the same way [sessionProvider] does, so a read failure surfaces
/// through [AsyncValue.error] rather than as a silently empty list.
final sessionFeedbackProvider =
    FutureProvider.family<List<SessionFeedback>, String>((ref, sessionId) async {
  final result =
      await ref.watch(feedbackRepositoryProvider).getFeedbackForSession(sessionId);
  return result.fold((failure) => throw failure, (feedback) => feedback);
});

/// A single session by id. Throws the [Failure] on a miss so it surfaces
/// through [AsyncValue.error] the same way the stream-backed providers do.
final sessionProvider = FutureProvider.family<Session, String>((ref, sessionId) async {
  final result = await ref.watch(sessionRepositoryProvider).getSession(sessionId);
  return result.fold((failure) => throw failure, (session) => session);
});
