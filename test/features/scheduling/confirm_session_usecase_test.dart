import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/confirm_session_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract repository interface (never the Firebase
/// implementation) per the team's testing pattern — see
/// test/features/auth_trust/auth_repository_test.dart. The transaction
/// itself lives in the data source and is not exercised here; the rule it
/// enforces is covered by session_conflict_detector_test.dart.
class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository sessionRepository;

  setUp(() {
    sessionRepository = MockSessionRepository();
  });

  final requested = Session(
    id: 'session-1',
    requesterId: 'elder-1',
    volunteerId: 'volunteer-1',
    scheduledAt: DateTime(2026, 9, 1, 10, 0),
    durationMinutes: 60,
    status: SessionStatus.requested,
    location: 'Community centre',
  );

  group('ConfirmSessionUseCase', () {
    test('delegates to SessionRepository.confirmSession and returns the '
        'confirmed Session', () async {
      final useCase = ConfirmSessionUseCase(sessionRepository);
      final confirmed = requested.copyWith(status: SessionStatus.confirmed);
      when(
        () => sessionRepository.confirmSession(
          sessionId: 'session-1',
          confirmingUserId: 'volunteer-1',
        ),
      ).thenAnswer((_) async => Right(confirmed));

      final result = await useCase(
        sessionId: 'session-1',
        confirmingUserId: 'volunteer-1',
      );

      expect(result, Right<Failure, Session>(confirmed));
      verify(
        () => sessionRepository.confirmSession(
          sessionId: 'session-1',
          confirmingUserId: 'volunteer-1',
        ),
      ).called(1);
    });

    test('surfaces the conflict message when the slot was taken first', () async {
      final useCase = ConfirmSessionUseCase(sessionRepository);
      when(
        () => sessionRepository.confirmSession(
          sessionId: 'session-1',
          confirmingUserId: 'volunteer-1',
        ),
      ).thenAnswer(
        (_) async =>
            const Left(UnknownFailure('This time slot is no longer available.')),
      );

      final result = await useCase(
        sessionId: 'session-1',
        confirmingUserId: 'volunteer-1',
      );

      result.fold(
        (failure) => expect(
          failure.message,
          'This time slot is no longer available.',
        ),
        (_) => fail('Expected a Left(Failure) for a taken slot'),
      );
    });

    test('surfaces a Left when the session is no longer confirmable', () async {
      final useCase = ConfirmSessionUseCase(sessionRepository);
      when(
        () => sessionRepository.confirmSession(
          sessionId: 'session-1',
          confirmingUserId: 'volunteer-1',
        ),
      ).thenAnswer(
        (_) async => const Left(
          UnknownFailure('This session is cancelled and can no longer be confirmed.'),
        ),
      );

      final result = await useCase(
        sessionId: 'session-1',
        confirmingUserId: 'volunteer-1',
      );

      expect(result.isLeft(), isTrue);
    });

    test('propagates a NotFoundFailure unchanged', () async {
      final useCase = ConfirmSessionUseCase(sessionRepository);
      when(
        () => sessionRepository.confirmSession(
          sessionId: 'missing',
          confirmingUserId: 'volunteer-1',
        ),
      ).thenAnswer((_) async => const Left(NotFoundFailure('Session not found.')));

      final result = await useCase(
        sessionId: 'missing',
        confirmingUserId: 'volunteer-1',
      );

      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Expected a Left(NotFoundFailure)'),
      );
    });
  });
}
