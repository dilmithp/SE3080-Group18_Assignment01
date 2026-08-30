import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';
import 'package:elderly_companion/features/auth_trust/domain/usecases/send_sign_in_link_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract [AuthRepository] interface (never a Firebase
/// implementation) per this repo's testing pattern — see
/// test/features/auth_trust/auth_repository_test.dart.
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late SendSignInLinkUseCase useCase;

  setUp(() {
    authRepository = MockAuthRepository();
    useCase = SendSignInLinkUseCase(authRepository);
  });

  group('SendSignInLinkUseCase', () {
    test('returns Right(null) when the repository sends the link', () async {
      when(
        () => authRepository.sendSignInLinkToEmail('ada@example.com'),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase('ada@example.com');

      expect(result, const Right<Failure, void>(null));
      verify(() => authRepository.sendSignInLinkToEmail('ada@example.com')).called(1);
    });

    test('returns Left(Failure) when the repository call fails', () async {
      when(
        () => authRepository.sendSignInLinkToEmail('ada@example.com'),
      ).thenAnswer((_) async => const Left(NetworkFailure('No network connection.')));

      final result = await useCase('ada@example.com');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected a Left(NetworkFailure)'),
      );
    });
  });
}
