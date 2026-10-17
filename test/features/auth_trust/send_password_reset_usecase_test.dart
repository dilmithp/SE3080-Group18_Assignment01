import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';
import 'package:elderly_companion/features/auth_trust/domain/usecases/send_password_reset_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract [AuthRepository] interface, never a Firebase
/// implementation (see test/features/auth_trust/auth_repository_test.dart).
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late SendPasswordResetUseCase useCase;

  setUp(() {
    authRepository = MockAuthRepository();
    useCase = SendPasswordResetUseCase(authRepository);
  });

  group('SendPasswordResetUseCase', () {
    test('returns Right(null) when the repository sends the reset email', () async {
      when(
        () => authRepository.sendPasswordResetEmail('ada@example.com'),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase('ada@example.com');

      expect(result, const Right<Failure, void>(null));
      verify(() => authRepository.sendPasswordResetEmail('ada@example.com')).called(1);
    });

    test('returns Left(Failure) when the repository call fails', () async {
      when(
        () => authRepository.sendPasswordResetEmail('ada@example.com'),
      ).thenAnswer((_) async => const Left(NetworkFailure('No network connection.')));

      final result = await useCase('ada@example.com');

      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected a Left(NetworkFailure)'),
      );
    });
  });
}
