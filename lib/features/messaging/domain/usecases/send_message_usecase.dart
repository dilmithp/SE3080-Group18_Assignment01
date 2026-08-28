import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/messaging/domain/repositories/messaging_repository.dart';

/// Single business rule: send one chat message into an existing
/// conversation.
class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final MessagingRepository _repository;

  Future<Either<Failure, void>> call({
    required String conversationId,
    required String senderId,
    required String text,
  }) {
    return _repository.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      text: text,
    );
  }
}
