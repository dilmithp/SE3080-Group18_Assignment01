import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/community/domain/repositories/community_repository.dart';

/// Single business rule: share a post with the community feed.
class CreatePostUseCase {
  const CreatePostUseCase(this._repository);

  final CommunityRepository _repository;

  Future<Either<Failure, void>> call({
    required String authorId,
    required String authorName,
    String? authorPhotoUrl,
    required String text,
  }) {
    return _repository.createPost(
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      text: text,
    );
  }
}
