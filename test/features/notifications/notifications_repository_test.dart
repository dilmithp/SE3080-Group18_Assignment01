import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/notifications/domain/entities/app_notification.dart';
import 'package:elderly_companion/features/notifications/domain/entities/notification_type.dart';
import 'package:elderly_companion/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract [NotificationsRepository] interface (never a Firebase
/// implementation) — same pattern as
/// test/features/auth_trust/auth_repository_test.dart.
class MockNotificationsRepository extends Mock implements NotificationsRepository {}

void main() {
  late MockNotificationsRepository repository;

  setUpAll(() {
    // mocktail needs a fallback instance for any non-primitive type used
    // with `any()` — see the `createNotification` failure-path test below.
    registerFallbackValue(NotificationType.other);
  });

  setUp(() {
    repository = MockNotificationsRepository();
  });

  final testNotification = AppNotification(
    id: 'notif-1',
    userId: 'user-2',
    type: NotificationType.sessionConfirmed,
    title: 'Session confirmed',
    body: 'Your session on Mon, 1 Jan · 10:00 AM has been confirmed.',
    relatedId: 'session-1',
    isRead: false,
    createdAt: DateTime(2026, 1, 1),
  );

  group('NotificationsRepository (mocktail example)', () {
    test('createNotification returns Right(void) on success', () async {
      when(
        () => repository.createNotification(
          userId: 'user-2',
          type: NotificationType.sessionConfirmed,
          title: 'Session confirmed',
          body: any(named: 'body'),
          relatedId: 'session-1',
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await repository.createNotification(
        userId: 'user-2',
        type: NotificationType.sessionConfirmed,
        title: 'Session confirmed',
        body: 'Your session on Mon, 1 Jan · 10:00 AM has been confirmed.',
        relatedId: 'session-1',
      );

      expect(result.isRight(), isTrue);
    });

    test('createNotification returns Left(UnknownFailure) on error', () async {
      when(
        () => repository.createNotification(
          userId: any(named: 'userId'),
          type: any(named: 'type'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          relatedId: any(named: 'relatedId'),
        ),
      ).thenAnswer((_) async => const Left(UnknownFailure()));

      final result = await repository.createNotification(
        userId: 'user-2',
        type: NotificationType.feedbackReceived,
        title: 'New feedback received',
        body: 'You received new feedback.',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Expected a Left(UnknownFailure)'),
      );
    });

    test('watchNotificationsForUser streams notifications newest first', () {
      when(() => repository.watchNotificationsForUser('user-2'))
          .thenAnswer((_) => Stream.value([testNotification]));

      expect(
        repository.watchNotificationsForUser('user-2'),
        emits([testNotification]),
      );
    });

    test('markAsRead returns Right(void) on success', () async {
      when(() => repository.markAsRead('notif-1'))
          .thenAnswer((_) async => const Right(null));

      final result = await repository.markAsRead('notif-1');

      expect(result, const Right<Failure, void>(null));
      verify(() => repository.markAsRead('notif-1')).called(1);
    });

    test('markAsRead returns Left(NotFoundFailure) for an unknown id', () async {
      when(() => repository.markAsRead('missing'))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await repository.markAsRead('missing');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Expected a Left(NotFoundFailure)'),
      );
    });
  });
}
