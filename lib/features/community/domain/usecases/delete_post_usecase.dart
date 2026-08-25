import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/community/domain/repositories/community_repository.dart';

/// Single business rule: remove a post the caller authored. Ownership is
/// enforced by [CommunityRepository.deletePost] (and, authoritatively, by
/// firestore.rules) — this use case is a thin delegation.
class DeletePostUseCase {
  const DeletePostUseCase(this._repository);

  final CommunityRepository _repository;

  Future<Either<Failure, void>> call({
    required String postId,
    required String authorId,
  }) {
    return _repository.deletePost(postId: postId, authorId: authorId);
  }
}
