/// Pure domain entity — zero `package:firebase_*` imports. Data-layer DTOs
/// (see data/models/community_post_dto.dart) convert Firestore documents to
/// and from this type; nothing outside data/ should know Firestore exists.
class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorId;

  /// Denormalized at write time from the author's profile so the feed
  /// doesn't need N extra reads to show who posted what.
  final String authorName;

  /// Denormalized at write time, same reasoning as [authorName]. Null when
  /// the author has no profile photo.
  final String? authorPhotoUrl;

  final String text;
  final DateTime createdAt;

  CommunityPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? text,
    DateTime? createdAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityPost &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          authorId == other.authorId &&
          authorName == other.authorName &&
          authorPhotoUrl == other.authorPhotoUrl &&
          text == other.text &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, authorId, authorName, authorPhotoUrl, text, createdAt);
}
