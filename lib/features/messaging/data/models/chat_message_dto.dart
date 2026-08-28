import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/messaging/domain/entities/chat_message.dart';

part 'chat_message_dto.freezed.dart';
part 'chat_message_dto.g.dart';

/// Firestore-shaped DTO for `conversations/{conversationId}/messages/{messageId}`.
/// Converts to/from the pure [ChatMessage] domain entity — see [toEntity] /
/// [fromEntity].
///
/// Dates are stored here as epoch milliseconds so this class stays
/// plain-JSON for local (de)serialization; the data source bridges
/// Firestore's `Timestamp` type at the boundary by hand rather than calling
/// `fromJson`/`toJson` directly against raw snapshot data.
@freezed
class ChatMessageDto with _$ChatMessageDto {
  const ChatMessageDto._();

  const factory ChatMessageDto({
    required String id,
    required String conversationId,
    required String senderId,
    required String text,
    required int createdAtMillis,
  }) = _ChatMessageDto;

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageDtoFromJson(json);

  factory ChatMessageDto.fromEntity(ChatMessage entity) => ChatMessageDto(
        id: entity.id,
        conversationId: entity.conversationId,
        senderId: entity.senderId,
        text: entity.text,
        createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      );

  ChatMessage toEntity() => ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      );
}
