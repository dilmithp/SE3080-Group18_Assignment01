import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/messaging/domain/entities/conversation.dart';

part 'conversation_dto.freezed.dart';
part 'conversation_dto.g.dart';

/// Firestore-shaped DTO for `conversations/{conversationId}`. Converts to/from
/// the pure [Conversation] domain entity — see [toEntity] / [fromEntity].
///
/// Dates are stored here as epoch milliseconds so this class stays
/// plain-JSON (no custom `Timestamp` converter needed) for local
/// (de)serialization; the data source is responsible for bridging
/// Firestore's `Timestamp` type at the boundary — see
/// `MessagingRemoteDataSource`, which builds/reads this DTO by hand against
/// raw snapshot data rather than calling `fromJson`/`toJson` directly.
@freezed
class ConversationDto with _$ConversationDto {
  const ConversationDto._();

  const factory ConversationDto({
    required String id,
    required List<String> participantIds,
    required String lastMessageText,
    required int lastMessageAtMillis,
    required int createdAtMillis,
  }) = _ConversationDto;

  factory ConversationDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationDtoFromJson(json);

  factory ConversationDto.fromEntity(Conversation entity) => ConversationDto(
        id: entity.id,
        participantIds: entity.participantIds,
        lastMessageText: entity.lastMessageText,
        lastMessageAtMillis: entity.lastMessageAt.millisecondsSinceEpoch,
        createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      );

  Conversation toEntity() => Conversation(
        id: id,
        participantIds: participantIds,
        lastMessageText: lastMessageText,
        lastMessageAt: DateTime.fromMillisecondsSinceEpoch(lastMessageAtMillis),
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      );
}
