import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';
import 'package:elderly_companion/features/auth_trust/domain/usecases/sign_out_everywhere_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late SignOutEverywhereUseCase useCase;

  setUp(() {
    authRepository = MockAuthRepository();
    useCase = SignOutEverywhereUseCase(authRepository);
  });

  group('SignOutEverywhereUseCase', () {
    test('returns Right(unit) when every session is revoked', () async {
      when(() => authRepository.signOutEverywhere())
          .thenAnswer((_) async => const Right(unit));

      final result = await useCase();

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => authRepository.signOutEverywhere()).called(1);
    });

    test('returns Left(AuthFailure) when revocation is refused', () async {
      when(() => authRepository.signOutEverywhere()).thenAnswer(
        (_) async => const Left(AuthFailure('Sign in first.')),
      );

      final result = await useCase();

      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('Expected a Left(AuthFailure)'),
      );
    });
  });
}
