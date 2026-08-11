import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_feedback.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/feedback_repository.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/book_session_usecase.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/submit_feedback_usecase.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/update_session_status_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract repository interfaces (never the Firebase
/// implementation) per the team's testing pattern — see
/// test/features/auth_trust/auth_repository_test.dart for the canonical
/// shape this copies.
class MockSessionRepository extends Mock implements SessionRepository {}

class MockFeedbackRepository extends Mock implements FeedbackRepository {}

void main() {
  late MockSessionRepository sessionRepository;
  late MockFeedbackRepository feedbackRepository;

  setUp(() {
    sessionRepository = MockSessionRepository();
    feedbackRepository = MockFeedbackRepository();
  });

  final scheduledAt = DateTime(2026, 9, 1, 10, 0);

  final testSession = Session(
    id: 'session-1',
    requesterId: 'user-1',
    volunteerId: 'user-2',
    scheduledAt: scheduledAt,
    durationMinutes: 60,
    status: SessionStatus.requested,
    location: 'Community centre',
  );

  group('BookSessionUseCase', () {
    test('delegates to SessionRepository.bookSession and returns Right(Session)', () async {
      final useCase = BookSessionUseCase(sessionRepository);
      when(
        () => sessionRepository.bookSession(
          requesterId: 'user-1',
          volunteerId: 'user-2',
          scheduledAt: scheduledAt,
          durationMinutes: 60,
          location: 'Community centre',
          notes: null,
        ),
      ).thenAnswer((_) async => Right(testSession));

      final result = await useCase(
        requesterId: 'user-1',
        volunteerId: 'user-2',
        scheduledAt: scheduledAt,
        durationMinutes: 60,
        location: 'Community centre',
      );

      expect(result, Right<Failure, Session>(testSession));
      verify(
        () => sessionRepository.bookSession(
          requesterId: 'user-1',
          volunteerId: 'user-2',
          scheduledAt: scheduledAt,
          durationMinutes: 60,
          location: 'Community centre',
          notes: null,
        ),
      ).called(1);
    });

    test('propagates a Left(Failure) from the repository unchanged', () async {
      final useCase = BookSessionUseCase(sessionRepository);
      when(
        () => sessionRepository.bookSession(
          requesterId: 'user-1',
          volunteerId: 'user-2',
          scheduledAt: scheduledAt,
          durationMinutes: 60,
          location: 'Community centre',
          notes: null,
        ),
      ).thenAnswer((_) async => const Left(UnknownFailure('boom')));

      final result = await useCase(
        requesterId: 'user-1',
        volunteerId: 'user-2',
        scheduledAt: scheduledAt,
        durationMinutes: 60,
        location: 'Community centre',
      );

      expect(result, const Left<Failure, Session>(UnknownFailure('boom')));
    });
  });

  group('UpdateSessionStatusUseCase', () {
    test('delegates to SessionRepository.updateSessionStatus and returns the '
        'updated Session', () async {
      final useCase = UpdateSessionStatusUseCase(sessionRepository);
      final confirmed = testSession.copyWith(status: SessionStatus.confirmed);
      when(
        () => sessionRepository.updateSessionStatus(
          sessionId: 'session-1',
          status: SessionStatus.confirmed,
        ),
      ).thenAnswer((_) async => Right(confirmed));

      final result = await useCase(
        sessionId: 'session-1',
        status: SessionStatus.confirmed,
      );

      expect(result, Right<Failure, Session>(confirmed));
    });
  });

  group('SubmitFeedbackUseCase', () {
    test('delegates to FeedbackRepository.submitFeedback and returns '
        'Right(SessionFeedback)', () async {
      final useCase = SubmitFeedbackUseCase(feedbackRepository);
      final feedback = SessionFeedback(
        sessionId: 'session-1',
        raterId: 'user-1',
        rating: 5,
        comment: 'Great session',
        createdAt: DateTime(2026, 9, 1, 11, 0),
      );
      when(
        () => feedbackRepository.submitFeedback(
          sessionId: 'session-1',
          raterId: 'user-1',
          rating: 5,
          comment: 'Great session',
        ),
      ).thenAnswer((_) async => Right(feedback));

      final result = await useCase(
        sessionId: 'session-1',
        raterId: 'user-1',
        rating: 5,
        comment: 'Great session',
      );

      expect(result, Right<Failure, SessionFeedback>(feedback));
    });
  });
}
