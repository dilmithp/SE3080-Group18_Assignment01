import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/features/scheduling/data/datasources/scheduling_remote_data_source.dart';
import 'package:elderly_companion/features/scheduling/data/repositories/feedback_repository_impl.dart';
import 'package:elderly_companion/features/scheduling/data/repositories/session_repository_impl.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/feedback_repository.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/book_session_usecase.dart';
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
  return SessionRepositoryImpl(ref.watch(schedulingRemoteDataSourceProvider));
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepositoryImpl(ref.watch(schedulingRemoteDataSourceProvider));
});

final bookSessionUseCaseProvider = Provider<BookSessionUseCase>((ref) {
  return BookSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final updateSessionStatusUseCaseProvider = Provider<UpdateSessionStatusUseCase>((ref) {
  return UpdateSessionStatusUseCase(ref.watch(sessionRepositoryProvider));
});

final submitFeedbackUseCaseProvider = Provider<SubmitFeedbackUseCase>((ref) {
  return SubmitFeedbackUseCase(ref.watch(feedbackRepositoryProvider));
});
