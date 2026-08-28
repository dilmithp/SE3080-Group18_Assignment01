import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/community/domain/entities/community_post.dart';

part 'community_post_dto.freezed.dart';
part 'community_post_dto.g.dart';

/// Firestore-shaped DTO for the `community_posts` collection. Converts to/
/// from the pure [CommunityPost] domain entity — see [toEntity] /
/// [CommunityPostDto.fromEntity]. `createdAt` is stored as epoch
/// milliseconds so this class stays plain-JSON (no custom `Timestamp`
/// converter needed); the data source is responsible for bridging
/// Firestore's `Timestamp` type at the boundary.
@freezed
class CommunityPostDto with _$CommunityPostDto {
  const CommunityPostDto._();

  const factory CommunityPostDto({
    required String id,
    required String authorId,
    required String authorName,
    String? authorPhotoUrl,
    required String text,
    required int createdAtMillis,
  }) = _CommunityPostDto;

  factory CommunityPostDto.fromJson(Map<String, dynamic> json) =>
      _$CommunityPostDtoFromJson(json);

  factory CommunityPostDto.fromEntity(CommunityPost entity) => CommunityPostDto(
        id: entity.id,
        authorId: entity.authorId,
        authorName: entity.authorName,
        authorPhotoUrl: entity.authorPhotoUrl,
        text: entity.text,
        createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      );

  CommunityPost toEntity() => CommunityPost(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        text: text,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      );
}
