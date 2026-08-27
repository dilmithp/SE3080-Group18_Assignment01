import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/recurrence_rule.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/recurring_booking_result.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';
import 'package:elderly_companion/features/scheduling/domain/usecases/book_recurring_session_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract repository interface (never the Firebase
/// implementation) per the team's testing pattern. The rule expansion these
/// dates come from is covered separately in recurrence_rule_test.dart.
class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  late MockSessionRepository repository;

  setUp(() {
    repository = MockSessionRepository();
  });

  // A Tuesday, 10:00.
  final anchor = DateTime(2026, 9, 1, 10, 0);
  final weekly = RecurrenceRule.tryParse('FREQ=WEEKLY;BYDAY=TU')!;

  /// Builds the session the repository would have written, so assertions can
  /// read back the arguments each call was made with.
  Session sessionFrom(Invocation invocation) {
    final args = invocation.namedArguments;
    return Session(
      id: 'session-${args[#scheduledAt]}',
      requesterId: args[#requesterId] as String,
      volunteerId: args[#volunteerId] as String,
      scheduledAt: args[#scheduledAt] as DateTime,
      durationMinutes: args[#durationMinutes] as int,
      status: SessionStatus.requested,
      location: args[#location] as String,
      notes: args[#notes] as String?,
      isRecurring: args[#isRecurring] as bool,
      recurrenceRule: args[#recurrenceRule] as String?,
      seriesId: args[#seriesId] as String?,
    );
  }

  void stubBooking({
    Either<Failure, Session> Function(Invocation invocation)? onCall,
  }) {
    when(
      () => repository.bookSession(
        requesterId: any(named: 'requesterId'),
        volunteerId: any(named: 'volunteerId'),
        scheduledAt: any(named: 'scheduledAt'),
        durationMinutes: any(named: 'durationMinutes'),
        location: any(named: 'location'),
        notes: any(named: 'notes'),
        isRecurring: any(named: 'isRecurring'),
        recurrenceRule: any(named: 'recurrenceRule'),
        seriesId: any(named: 'seriesId'),
      ),
    ).thenAnswer(
      (invocation) async =>
          onCall?.call(invocation) ?? Right(sessionFrom(invocation)),
    );
  }

  Future<Either<Failure, RecurringBookingResult>> run({
    int? occurrenceCount,
    RecurrenceRule? rule,
    String seriesId = 'series-test',
  }) {
    final useCase = BookRecurringSessionUseCase(
      repository,
      seriesIdGenerator: () => seriesId,
    );
    return useCase(
      requesterId: 'elder-1',
      volunteerId: 'volunteer-1',
      scheduledAt: anchor,
      durationMinutes: 60,
      location: 'Community centre',
      recurrence: rule ?? weekly,
      notes: 'Ring twice',
      occurrenceCount:
          occurrenceCount ?? BookRecurringSessionUseCase.defaultOccurrenceCount,
    );
  }

  group('successful series creation', () {
    test('books the default eight occurrences, one per rule date', () async {
      stubBooking();

      final result = await run();

      final booked = result.getOrElse(() => throw StateError('expected Right'));
      expect(booked.sessions.length, BookRecurringSessionUseCase.defaultOccurrenceCount);
      expect(booked.skippedOccurrences, isEmpty);
      expect(booked.isComplete, isTrue);
      expect(booked.requestedCount, 8);
      verify(
        () => repository.bookSession(
          requesterId: any(named: 'requesterId'),
          volunteerId: any(named: 'volunteerId'),
          scheduledAt: any(named: 'scheduledAt'),
          durationMinutes: any(named: 'durationMinutes'),
          location: any(named: 'location'),
          notes: any(named: 'notes'),
          isRecurring: any(named: 'isRecurring'),
          recurrenceRule: any(named: 'recurrenceRule'),
          seriesId: any(named: 'seriesId'),
        ),
      ).called(8);
    });

    test('books the dates the rule produces, in order', () async {
      stubBooking();

      final result = await run(occurrenceCount: 3);
      final booked = result.getOrElse(() => throw StateError('expected Right'));

      expect(
        booked.sessions.map((session) => session.scheduledAt).toList(),
        [
          DateTime(2026, 9, 1, 10, 0),
          DateTime(2026, 9, 8, 10, 0),
          DateTime(2026, 9, 15, 10, 0),
        ],
      );
    });

    test('stamps every occurrence with the same seriesId and rule string',
        () async {
      stubBooking();

      final result = await run(occurrenceCount: 4, seriesId: 'series-abc');
      final booked = result.getOrElse(() => throw StateError('expected Right'));

      expect(booked.seriesId, 'series-abc');
      for (final session in booked.sessions) {
        expect(session.seriesId, 'series-abc');
        expect(session.isRecurring, isTrue);
        expect(session.recurrenceRule, 'FREQ=WEEKLY;BYDAY=TU');
      }
    });

    test('passes the booking details through unchanged', () async {
      stubBooking();

      final result = await run(occurrenceCount: 2);
      final booked = result.getOrElse(() => throw StateError('expected Right'));
      final first = booked.sessions.first;

      expect(first.requesterId, 'elder-1');
      expect(first.volunteerId, 'volunteer-1');
      expect(first.durationMinutes, 60);
      expect(first.location, 'Community centre');
      expect(first.notes, 'Ring twice');
    });

    test('honours a fortnightly rule with two days a week', () async {
      stubBooking();

      final result = await run(
        occurrenceCount: 4,
        rule: RecurrenceRule.tryParse('FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH')!,
      );
      final booked = result.getOrElse(() => throw StateError('expected Right'));

      expect(
        booked.sessions.map((session) => session.scheduledAt).toList(),
        [
          DateTime(2026, 9, 1, 10, 0), // Tue
          DateTime(2026, 9, 3, 10, 0), // Thu
          DateTime(2026, 9, 15, 10, 0), // Tue, two weeks on
          DateTime(2026, 9, 17, 10, 0), // Thu
        ],
      );
      expect(
        booked.sessions.first.recurrenceRule,
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH',
      );
    });

    test('generates a distinct series id per run when none is injected',
        () async {
      stubBooking();
      final useCase = BookRecurringSessionUseCase(repository);

      Future<String> bookOnce() async {
        final result = await useCase(
          requesterId: 'elder-1',
          volunteerId: 'volunteer-1',
          scheduledAt: anchor,
          durationMinutes: 60,
          location: 'Community centre',
          recurrence: weekly,
          occurrenceCount: 1,
        );
        return result
            .getOrElse(() => throw StateError('expected Right'))
            .seriesId;
      }

      final first = await bookOnce();
      final second = await bookOnce();

      expect(first, isNotEmpty);
      expect(first, isNot(second));
    });
  });

  group('first occurrence fails', () {
    test('returns the failure and writes nothing else', () async {
      var calls = 0;
      stubBooking(
        onCall: (_) {
          calls++;
          return const Left(
            UnknownFailure('This time slot is no longer available.'),
          );
        },
      );

      final result = await run();

      expect(calls, 1, reason: 'no occurrence after the first may be written');
      result.fold(
        (failure) =>
            expect(failure.message, 'This time slot is no longer available.'),
        (_) => fail('Expected a Left(Failure) when the first booking fails'),
      );
    });

    test('propagates the failure type unchanged', () async {
      stubBooking(onCall: (_) => const Left(NetworkFailure()));

      final result = await run();

      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected a Left(NetworkFailure)'),
      );
    });
  });

  group('a later occurrence fails', () {
    test('keeps the earlier writes and reports the skipped date', () async {
      var calls = 0;
      stubBooking(
        onCall: (invocation) {
          calls++;
          if (calls == 3) {
            return const Left(UnknownFailure('Write failed.'));
          }
          return Right(sessionFrom(invocation));
        },
      );

      final result = await run(occurrenceCount: 4);
      final booked = result.getOrElse(() => throw StateError('expected Right'));

      expect(booked.sessions.length, 3);
      expect(booked.skippedOccurrences, [DateTime(2026, 9, 15, 10, 0)]);
      expect(booked.isComplete, isFalse);
      expect(booked.requestedCount, 4);
    });
  });

  group('guards', () {
    test('refuses a non-positive occurrence count without touching the '
        'repository', () async {
      stubBooking();

      final result = await run(occurrenceCount: 0);

      expect(result.isLeft(), isTrue);
      verifyNever(
        () => repository.bookSession(
          requesterId: any(named: 'requesterId'),
          volunteerId: any(named: 'volunteerId'),
          scheduledAt: any(named: 'scheduledAt'),
          durationMinutes: any(named: 'durationMinutes'),
          location: any(named: 'location'),
          notes: any(named: 'notes'),
          isRecurring: any(named: 'isRecurring'),
          recurrenceRule: any(named: 'recurrenceRule'),
          seriesId: any(named: 'seriesId'),
        ),
      );
    });

    test('books a single occurrence when asked for one', () async {
      stubBooking();

      final result = await run(occurrenceCount: 1);
      final booked = result.getOrElse(() => throw StateError('expected Right'));

      expect(booked.sessions.single.scheduledAt, anchor);
    });
  });
}
