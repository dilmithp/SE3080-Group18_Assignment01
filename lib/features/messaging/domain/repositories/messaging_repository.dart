import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/messaging/domain/entities/chat_message.dart';
import 'package:elderly_companion/features/messaging/domain/entities/conversation.dart';

/// Contract for 1:1 messaging between a matched elderly user and volunteer.
///
/// A [Conversation] is keyed by a deterministic ID (the two participant UIDs
/// sorted ascending and joined with `_`), so "get or create" never needs a
/// query — see [getOrCreateConversation].
///
/// Owner: messaging.
abstract class MessagingRepository {
  /// Reads the conversation between [userId] and [otherUserId], creating it
  /// (with an empty `lastMessageText`) if it doesn't exist yet.
  Future<Either<Failure, Conversation>> getOrCreateConversation({
    required String userId,
    required String otherUserId,
  });

  /// Every conversation [userId] is a participant of, most recently active
  /// first.
  Stream<List<Conversation>> watchConversationsForUser(String userId);

  /// Every message in [conversationId], oldest first.
  Stream<List<ChatMessage>> watchMessages(String conversationId);

  /// Appends one message to [conversationId] and updates its
  /// `lastMessageText`/`lastMessageAt` preview fields.
  Future<Either<Failure, void>> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });
}
