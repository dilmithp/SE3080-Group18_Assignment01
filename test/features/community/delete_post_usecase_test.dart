import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/community/domain/repositories/community_repository.dart';
import 'package:elderly_companion/features/community/domain/usecases/delete_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract [CommunityRepository] interface (never the Firebase
/// implementation) — see test/features/auth_trust/auth_repository_test.dart
/// for the canonical shape this copies.
class MockCommunityRepository extends Mock implements CommunityRepository {}

void main() {
  late MockCommunityRepository repository;
  late DeletePostUseCase useCase;

  setUp(() {
    repository = MockCommunityRepository();
    useCase = DeletePostUseCase(repository);
  });

  group('DeletePostUseCase', () {
    test('delegates to the repository and returns Right(void) on success', () async {
      when(
        () => repository.deletePost(postId: 'post-1', authorId: 'user-1'),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(postId: 'post-1', authorId: 'user-1');

      expect(result, const Right<Failure, void>(null));
      verify(
        () => repository.deletePost(postId: 'post-1', authorId: 'user-1'),
      ).called(1);
    });

    test('returns Left(PermissionFailure) when the caller does not own the post', () async {
      when(
        () => repository.deletePost(postId: 'post-1', authorId: 'user-2'),
      ).thenAnswer(
        (_) async => const Left(PermissionFailure('You can only delete your own posts.')),
      );

      final result = await useCase(postId: 'post-1', authorId: 'user-2');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<PermissionFailure>()),
        (_) => fail('Expected a Left(PermissionFailure)'),
      );
    });

    test('returns Left(NotFoundFailure) when the post no longer exists', () async {
      when(
        () => repository.deletePost(postId: 'missing', authorId: 'user-1'),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase(postId: 'missing', authorId: 'user-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Expected a Left(NotFoundFailure)'),
      );
    });
  });
}
