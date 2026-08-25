import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:elderly_companion/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract repository interface (never the Firebase
/// implementation) per the team's testing pattern — see
/// test/features/auth_trust/auth_repository_test.dart.
class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository messagingRepository;

  setUp(() {
    messagingRepository = MockMessagingRepository();
  });

  group('SendMessageUseCase', () {
    test('delegates to MessagingRepository.sendMessage and returns Right(null) '
        'on success', () async {
      final useCase = SendMessageUseCase(messagingRepository);
      when(
        () => messagingRepository.sendMessage(
          conversationId: 'elder-1_volunteer-1',
          senderId: 'elder-1',
          text: 'Hello there!',
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        conversationId: 'elder-1_volunteer-1',
        senderId: 'elder-1',
        text: 'Hello there!',
      );

      expect(result, const Right<Failure, void>(null));
      verify(
        () => messagingRepository.sendMessage(
          conversationId: 'elder-1_volunteer-1',
          senderId: 'elder-1',
          text: 'Hello there!',
        ),
      ).called(1);
    });

    test('propagates a Left(Failure) unchanged', () async {
      final useCase = SendMessageUseCase(messagingRepository);
      when(
        () => messagingRepository.sendMessage(
          conversationId: 'elder-1_volunteer-1',
          senderId: 'elder-1',
          text: 'Hello there!',
        ),
      ).thenAnswer((_) async => const Left(PermissionFailure('Not a participant.')));

      final result = await useCase(
        conversationId: 'elder-1_volunteer-1',
        senderId: 'elder-1',
        text: 'Hello there!',
      );

      result.fold(
        (failure) => expect(failure, isA<PermissionFailure>()),
        (_) => fail('Expected a Left(PermissionFailure)'),
      );
    });
  });
}
