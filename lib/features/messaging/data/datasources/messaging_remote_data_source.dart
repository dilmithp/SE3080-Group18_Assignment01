import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/features/messaging/data/models/chat_message_dto.dart';
import 'package:elderly_companion/features/messaging/data/models/conversation_dto.dart';

/// Firestore collection names for messaging. Kept local to this feature
/// (rather than in `core/config/app_config.dart`) per the strict file
/// boundary this feature was built under — `core/` needs a two-reviewer
/// pass, so a later integration pass can fold these into `AppConfig` if the
/// team wants that centralised.
class MessagingCollections {
  const MessagingCollections._();

  static const String conversations = 'conversations';
  static const String messagesSubcollection = 'messages';

  static String messagesPath(String conversationId) =>
      '$conversations/$conversationId/$messagesSubcollection';
}

/// Raw Firebase calls for 1:1 messaging. Throws the exceptions in
/// core/error/exceptions.dart; [MessagingRepositoryImpl] translates those
/// into [Failure]s.
abstract class MessagingRemoteDataSource {
  /// Reads `conversations/{conversationId}` for the deterministic ID formed
  /// from [userId] and [otherUserId] (see
  /// [MessagingRemoteDataSource.conversationIdFor]), creating it with an
  /// empty `lastMessageText` if it doesn't exist yet.
  Future<ConversationDto> getOrCreateConversation({
    required String userId,
    required String otherUserId,
  });

  Stream<List<ConversationDto>> watchConversationsForUser(String userId);

  Stream<List<ChatMessageDto>> watchMessages(String conversationId);

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });
}

class FirebaseMessagingRemoteDataSource implements MessagingRemoteDataSource {
  FirebaseMessagingRemoteDataSource({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  /// The two participant UIDs sorted ascending and joined with `_` — same
  /// pair, same doc ID, regardless of who initiates. Lets "get or create" be
  /// a plain doc read/set instead of a `participantIds` query.
  static String conversationIdFor(String userId, String otherUserId) {
    final sorted = [userId, otherUserId]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  Future<ConversationDto> getOrCreateConversation({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      final id = conversationIdFor(userId, otherUserId);
      final docRef =
          _firestoreService.collection(MessagingCollections.conversations).doc(id);
      final existing = await docRef.get();
      final existingData = existing.data();
      if (existingData != null) {
        return _conversationDtoFromData(id, existingData);
      }

      final now = Timestamp.now();
      final participantIds = [userId, otherUserId]..sort();
      await _firestoreService.setDocument(
        collectionPath: MessagingCollections.conversations,
        docId: id,
        data: {
          'participantIds': participantIds,
          'lastMessageText': '',
          'lastMessageAt': now,
          'createdAt': now,
        },
      );
      return ConversationDto(
        id: id,
        participantIds: participantIds,
        lastMessageText: '',
        lastMessageAtMillis: now.millisecondsSinceEpoch,
        createdAtMillis: now.millisecondsSinceEpoch,
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<List<ConversationDto>> watchConversationsForUser(String userId) {
    return _firestoreService
        .collection(MessagingCollections.conversations)
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => _conversationDtoFromData(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<ChatMessageDto>> watchMessages(String conversationId) {
    return _firestoreService
        .collection(MessagingCollections.messagesPath(conversationId))
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => _chatMessageDtoFromData(doc.id, conversationId, doc.data()),
              )
              .toList(),
        );
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    try {
      final now = Timestamp.now();
      final messageId =
          _firestoreService.newDocId(MessagingCollections.messagesPath(conversationId));
      await _firestoreService.setDocument(
        collectionPath: MessagingCollections.messagesPath(conversationId),
        docId: messageId,
        data: {
          'senderId': senderId,
          'text': text,
          'createdAt': now,
        },
      );
      await _firestoreService.setDocument(
        collectionPath: MessagingCollections.conversations,
        docId: conversationId,
        data: {
          'lastMessageText': text,
          'lastMessageAt': now,
        },
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } catch (_) {
      throw const ServerException();
    }
  }

  ConversationDto _conversationDtoFromData(String id, Map<String, dynamic> data) {
    return ConversationDto(
      id: id,
      participantIds: List<String>.from(data['participantIds'] as List<dynamic>),
      lastMessageText: data['lastMessageText'] as String? ?? '',
      lastMessageAtMillis:
          (data['lastMessageAt'] as Timestamp?)?.millisecondsSinceEpoch ??
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
      createdAtMillis: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
    );
  }

  ChatMessageDto _chatMessageDtoFromData(
    String id,
    String conversationId,
    Map<String, dynamic> data,
  ) {
    return ChatMessageDto(
      id: id,
      conversationId: conversationId,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      createdAtMillis: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
    );
  }
}
