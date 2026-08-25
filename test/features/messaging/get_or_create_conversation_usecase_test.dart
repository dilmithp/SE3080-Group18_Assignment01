import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/messaging/domain/entities/conversation.dart';
import 'package:elderly_companion/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:elderly_companion/features/messaging/domain/usecases/get_or_create_conversation_usecase.dart';
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

  final conversation = Conversation(
    id: 'elder-1_volunteer-1',
    participantIds: const ['elder-1', 'volunteer-1'],
    lastMessageText: '',
    lastMessageAt: DateTime(2026, 8, 1, 9, 0),
    createdAt: DateTime(2026, 8, 1, 9, 0),
  );

  group('GetOrCreateConversationUseCase', () {
    test(
        'delegates to MessagingRepository.getOrCreateConversation and '
        'returns Right(Conversation)', () async {
      final useCase = GetOrCreateConversationUseCase(messagingRepository);
      when(
        () => messagingRepository.getOrCreateConversation(
          userId: 'elder-1',
          otherUserId: 'volunteer-1',
        ),
      ).thenAnswer((_) async => Right(conversation));

      final result = await useCase(userId: 'elder-1', otherUserId: 'volunteer-1');

      expect(result, Right<Failure, Conversation>(conversation));
      verify(
        () => messagingRepository.getOrCreateConversation(
          userId: 'elder-1',
          otherUserId: 'volunteer-1',
        ),
      ).called(1);
    });

    test('propagates a Left(Failure) unchanged', () async {
      final useCase = GetOrCreateConversationUseCase(messagingRepository);
      when(
        () => messagingRepository.getOrCreateConversation(
          userId: 'elder-1',
          otherUserId: 'volunteer-1',
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure('No network connection.')));

      final result = await useCase(userId: 'elder-1', otherUserId: 'volunteer-1');

      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected a Left(NetworkFailure)'),
      );
    });
  });
}
