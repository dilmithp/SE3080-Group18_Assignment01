import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/features/messaging/data/datasources/messaging_remote_data_source.dart';
import 'package:elderly_companion/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:elderly_companion/features/messaging/domain/entities/chat_message.dart';
import 'package:elderly_companion/features/messaging/domain/entities/conversation.dart';
import 'package:elderly_companion/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:elderly_companion/features/messaging/domain/usecases/get_or_create_conversation_usecase.dart';
import 'package:elderly_companion/features/messaging/domain/usecases/send_message_usecase.dart';

/// All Dependency-Inversion wiring for messaging lives here: presentation
/// and domain depend only on the abstract [MessagingRepository] interface;
/// this file is the only place that knows [MessagingRepositoryImpl] etc.
/// exist.

final messagingRemoteDataSourceProvider = Provider<MessagingRemoteDataSource>((ref) {
  return FirebaseMessagingRemoteDataSource(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepositoryImpl(ref.watch(messagingRemoteDataSourceProvider));
});

final getOrCreateConversationUseCaseProvider =
    Provider<GetOrCreateConversationUseCase>((ref) {
  return GetOrCreateConversationUseCase(ref.watch(messagingRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(messagingRepositoryProvider));
});

/// Live list of a user's conversations, most recently active first.
final conversationsForUserProvider =
    StreamProvider.family<List<Conversation>, String>((ref, userId) {
  return ref.watch(messagingRepositoryProvider).watchConversationsForUser(userId);
});

/// Live list of messages in one conversation, oldest first.
final messagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, conversationId) {
  return ref.watch(messagingRepositoryProvider).watchMessages(conversationId);
});
