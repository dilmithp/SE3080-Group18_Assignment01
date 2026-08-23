import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/series_cancellation_result.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/cancel_series_usecase.dart';
import 'package:elderly_companion/features/scheduling/presentation/screens/session_series_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract repository interface (never the Firebase
/// implementation) per the team's testing pattern. Which occurrences are
/// eligible is covered in session_series_test.dart; this pins what happens
/// when the writes for them succeed, fail, or are not needed at all.
class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  setUpAll(() => registerFallbackValue(SessionStatus.cancelled));

  late MockSessionRepository repository;
  late CancelSeriesUseCase useCase;

  setUp(() {
    repository = MockSessionRepository();
    useCase = CancelSeriesUseCase(repository);
  });

  Session session({
    required String id,
    String? seriesId = 'series-1',
    int day = 1,
    SessionStatus status = SessionStatus.confirmed,
  }) {
    return Session(
      id: id,
      requesterId: 'elder-1',
      volunteerId: 'volunteer-1',
      scheduledAt: DateTime(2026, 9, day, 10, 0),
      durationMinutes: 60,
      status: status,
      location: 'Community centre',
      isRecurring: seriesId != null,
      seriesId: seriesId,
    );
  }

  void stubCancel({
    Either<Failure, Session> Function(String sessionId)? onCall,
  }) {
    when(
      () => repository.updateSessionStatus(
        sessionId: any(named: 'sessionId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((invocation) async {
      final id = invocation.namedArguments[#sessionId] as String;
      return onCall?.call(id) ??
          Right(session(id: id, status: SessionStatus.cancelled));
    });
  }

  group('success', () {
    test('cancels every open occurrence in the series', () async {
      stubCancel();
      final occurrences = [
        session(id: 'a', day: 1, status: SessionStatus.requested),
        session(id: 'b', day: 8),
        session(id: 'c', day: 15),
      ];

      final result = await useCase(seriesId: 'series-1', occurrences: occurrences);
      final cancellation =
          result.getOrElse(() => throw StateError('expected Right'));

      expect(cancellation.cancelledSessions.length, 3);
      expect(cancellation.failedSessionIds, isEmpty);
      expect(cancellation.isComplete, isTrue);
      expect(cancellation.nothingToCancel, isFalse);
      expect(cancellation.seriesId, 'series-1');
      verify(
        () => repository.updateSessionStatus(
          sessionId: any(named: 'sessionId'),
          status: SessionStatus.cancelled,
        ),
      ).called(3);
    });

    test('leaves completed and already-cancelled occurrences alone', () async {
      stubCancel();
      final occurrences = [
        session(id: 'done', status: SessionStatus.completed),
        session(id: 'gone', day: 8, status: SessionStatus.cancelled),
        session(id: 'open', day: 15),
      ];

      final result = await useCase(seriesId: 'series-1', occurrences: occurrences);
      final cancellation =
          result.getOrElse(() => throw StateError('expected Right'));

      expect(cancellation.cancelledSessions.single.id, 'open');
      verify(
        () => repository.updateSessionStatus(
          sessionId: 'open',
          status: SessionStatus.cancelled,
        ),
      ).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('ignores sessions belonging to another series', () async {
      stubCancel();
      final occurrences = [
        session(id: 'mine'),
        session(id: 'theirs', day: 8, seriesId: 'series-2'),
        session(id: 'oneOff', day: 9, seriesId: null),
      ];

      final result = await useCase(seriesId: 'series-1', occurrences: occurrences);
      final cancellation =
          result.getOrElse(() => throw StateError('expected Right'));

      expect(cancellation.cancelledSessions.single.id, 'mine');
    });
  });

  group('partial success', () {
    test('reports what failed instead of claiming the series is cancelled',
        () async {
      stubCancel(
        onCall: (id) => id == 'b'
            ? const Left(NetworkFailure())
            : Right(session(id: id, status: SessionStatus.cancelled)),
      );
      final occurrences = [
        session(id: 'a', day: 1),
        session(id: 'b', day: 8),
        session(id: 'c', day: 15),
      ];

      final result = await useCase(seriesId: 'series-1', occurrences: occurrences);
      final cancellation =
          result.getOrElse(() => throw StateError('expected Right'));

      expect(cancellation.cancelledSessions.map((s) => s.id), ['a', 'c']);
      expect(cancellation.failedSessionIds, ['b']);
      expect(cancellation.isComplete, isFalse);
      expect(cancellation.attemptedCount, 3);
    });

    test('carries on after a failure rather than stopping at it', () async {
      stubCancel(
        onCall: (id) => id == 'a'
            ? const Left(UnknownFailure('Write failed.'))
            : Right(session(id: id, status: SessionStatus.cancelled)),
      );

      final result = await useCase(
        seriesId: 'series-1',
        occurrences: [session(id: 'a', day: 1), session(id: 'b', day: 8)],
      );
      final cancellation =
          result.getOrElse(() => throw StateError('expected Right'));

      expect(cancellation.cancelledSessions.single.id, 'b');
      expect(cancellation.failedSessionIds, ['a']);
    });
  });

  group('nothing to cancel', () {
    test('succeeds without writing when every occurrence has settled',
        () async {
      stubCancel();
      final occurrences = [
        session(id: 'a', status: SessionStatus.completed),
        session(id: 'b', day: 8, status: SessionStatus.cancelled),
      ];

      final result = await useCase(seriesId: 'series-1', occurrences: occurrences);
      final cancellation =
          result.getOrElse(() => throw StateError('expected Right'));

      expect(cancellation.nothingToCancel, isTrue);
      expect(cancellation.isComplete, isTrue);
      expect(cancellation.attemptedCount, 0);
      verifyNever(
        () => repository.updateSessionStatus(
          sessionId: any(named: 'sessionId'),
          status: any(named: 'status'),
        ),
      );
    });

    test('succeeds without writing for an empty occurrence list', () async {
      stubCancel();

      final result = await useCase(seriesId: 'series-1', occurrences: const []);

      expect(
        result.getOrElse(() => throw StateError('expected Right')).nothingToCancel,
        isTrue,
      );
      verifyNever(
        () => repository.updateSessionStatus(
          sessionId: any(named: 'sessionId'),
          status: any(named: 'status'),
        ),
      );
    });

    test('refuses a blank series id', () async {
      stubCancel();

      final result = await useCase(seriesId: '', occurrences: [session(id: 'a')]);

      expect(result.isLeft(), isTrue);
      verifyNever(
        () => repository.updateSessionStatus(
          sessionId: any(named: 'sessionId'),
          status: any(named: 'status'),
        ),
      );
    });
  });

  group('seriesCancellationMessage', () {
    SeriesCancellationResult resultWith({
      required int cancelled,
      List<String> failed = const [],
    }) {
      return SeriesCancellationResult(
        seriesId: 'series-1',
        cancelledSessions: [
          for (var i = 0; i < cancelled; i++) session(id: 'id-$i', day: i + 1),
        ],
        failedSessionIds: failed,
      );
    }

    test('states the count on a clean run', () {
      expect(
        seriesCancellationMessage(resultWith(cancelled: 3)),
        'Cancelled 3 sessions.',
      );
    });

    test('reads naturally for a single cancellation', () {
      expect(
        seriesCancellationMessage(resultWith(cancelled: 1)),
        'Session cancelled.',
      );
    });

    test('says nothing was left to do rather than claiming a cancellation', () {
      final message = seriesCancellationMessage(resultWith(cancelled: 0));

      expect(message, contains('Nothing left to cancel'));
    });

    test('does not claim success when some cancellations failed', () {
      final message = seriesCancellationMessage(
        resultWith(cancelled: 2, failed: ['x', 'y']),
      );

      expect(message, contains('Cancelled 2 of 4 sessions'));
      expect(message, contains('2 could not be cancelled'));
      expect(message, contains('are'));
    });

    test('uses the singular for one failure', () {
      final message = seriesCancellationMessage(
        resultWith(cancelled: 2, failed: ['x']),
      );

      expect(message, contains('Cancelled 2 of 3 sessions'));
      expect(message, contains('is'));
    });
  });
}
