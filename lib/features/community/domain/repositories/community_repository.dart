import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/community/domain/entities/community_post.dart';

/// Abstract interface for the community feed — presentation and domain
/// depend only on this; `data/repositories/community_repository_impl.dart`
/// is the only implementation.
abstract class CommunityRepository {
  /// Creates one post. [authorName]/[authorPhotoUrl] are denormalized from
  /// the caller's profile at write time — see `CommunityPost.authorName`.
  Future<Either<Failure, void>> createPost({
    required String authorId,
    required String authorName,
    String? authorPhotoUrl,
    required String text,
  });

  /// Every post, newest first, capped at a reasonable limit.
  Stream<List<CommunityPost>> watchFeed();

  /// Deletes [postId]. Only the original author may delete their own post —
  /// enforced by firestore.rules (`delete: isOwner(resource.data.authorId)`),
  /// not just this client-side check.
  Future<Either<Failure, void>> deletePost({
    required String postId,
    required String authorId,
  });
}
