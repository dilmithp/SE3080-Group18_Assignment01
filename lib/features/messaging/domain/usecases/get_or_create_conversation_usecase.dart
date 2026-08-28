import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/messaging/domain/entities/conversation.dart';
import 'package:elderly_companion/features/messaging/domain/repositories/messaging_repository.dart';

/// Single business rule: find the conversation between two users, creating
/// it on first contact.
class GetOrCreateConversationUseCase {
  const GetOrCreateConversationUseCase(this._repository);

  final MessagingRepository _repository;

  Future<Either<Failure, Conversation>> call({
    required String userId,
    required String otherUserId,
  }) {
    return _repository.getOrCreateConversation(
      userId: userId,
      otherUserId: otherUserId,
    );
  }
}
