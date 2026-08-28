import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/community/domain/repositories/community_repository.dart';
import 'package:elderly_companion/features/community/domain/usecases/create_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract [CommunityRepository] interface (never the Firebase
/// implementation) — see test/features/auth_trust/auth_repository_test.dart
/// for the canonical shape this copies.
class MockCommunityRepository extends Mock implements CommunityRepository {}

void main() {
  late MockCommunityRepository repository;
  late CreatePostUseCase useCase;

  setUp(() {
    repository = MockCommunityRepository();
    useCase = CreatePostUseCase(repository);
  });

  group('CreatePostUseCase', () {
    test('delegates to the repository and returns Right(void) on success', () async {
      when(
        () => repository.createPost(
          authorId: 'user-1',
          authorName: 'Ada',
          authorPhotoUrl: 'https://example.com/ada.jpg',
          text: 'Thank you to my volunteer this week!',
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        authorId: 'user-1',
        authorName: 'Ada',
        authorPhotoUrl: 'https://example.com/ada.jpg',
        text: 'Thank you to my volunteer this week!',
      );

      expect(result, const Right<Failure, void>(null));
      verify(
        () => repository.createPost(
          authorId: 'user-1',
          authorName: 'Ada',
          authorPhotoUrl: 'https://example.com/ada.jpg',
          text: 'Thank you to my volunteer this week!',
        ),
      ).called(1);
    });

    test('passes a null authorPhotoUrl through unchanged', () async {
      when(
        () => repository.createPost(
          authorId: 'user-2',
          authorName: 'Sam',
          authorPhotoUrl: null,
          text: 'Looking for company on Tuesday.',
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        authorId: 'user-2',
        authorName: 'Sam',
        text: 'Looking for company on Tuesday.',
      );

      expect(result.isRight(), isTrue);
    });

    test('returns Left(Failure) when the repository fails', () async {
      when(
        () => repository.createPost(
          authorId: 'user-1',
          authorName: 'Ada',
          authorPhotoUrl: null,
          text: 'Hello everyone',
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(
        authorId: 'user-1',
        authorName: 'Ada',
        text: 'Hello everyone',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected a Left(NetworkFailure)'),
      );
    });
  });
}
