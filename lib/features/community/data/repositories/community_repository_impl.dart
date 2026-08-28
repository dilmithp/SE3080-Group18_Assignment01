import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/community/data/datasources/community_remote_data_source.dart';
import 'package:elderly_companion/features/community/domain/entities/community_post.dart';
import 'package:elderly_companion/features/community/domain/repositories/community_repository.dart';

/// Satisfies [CommunityRepository] by delegating to [_dataSource] and
/// mapping data-layer exceptions to [Failure]s.
class CommunityRepositoryImpl implements CommunityRepository {
  const CommunityRepositoryImpl(this._dataSource);

  final CommunityRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, void>> createPost({
    required String authorId,
    required String authorName,
    String? authorPhotoUrl,
    required String text,
  }) async {
    try {
      await _dataSource.createPost(
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        text: text,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<List<CommunityPost>> watchFeed() {
    return _dataSource
        .watchFeed()
        .map((dtos) => dtos.map((dto) => dto.toEntity()).toList());
  }

  @override
  Future<Either<Failure, void>> deletePost({
    required String postId,
    required String authorId,
  }) async {
    try {
      await _dataSource.deletePost(postId: postId, authorId: authorId);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
