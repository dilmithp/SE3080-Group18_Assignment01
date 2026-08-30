import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/app_user.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';
import 'package:elderly_companion/features/auth_trust/domain/usecases/sign_in_with_email_link_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract [AuthRepository] interface (never a Firebase
/// implementation) per this repo's testing pattern — see
/// test/features/auth_trust/auth_repository_test.dart.
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late SignInWithEmailLinkUseCase useCase;

  setUp(() {
    authRepository = MockAuthRepository();
    useCase = SignInWithEmailLinkUseCase(authRepository);
  });

  final testUser = AppUser(
    id: 'user-1',
    email: 'ada@example.com',
    phone: '',
    role: UserRole.elderly,
    isVerified: false,
    createdAt: DateTime(2026, 1, 1),
  );

  group('SignInWithEmailLinkUseCase', () {
    test('returns Right(AppUser) on a valid link', () async {
      when(
        () => authRepository.signInWithEmailLink(
          email: 'ada@example.com',
          emailLink: 'https://app.example.com/?oobCode=abc',
        ),
      ).thenAnswer((_) async => Right(testUser));

      final result = await useCase(
        email: 'ada@example.com',
        emailLink: 'https://app.example.com/?oobCode=abc',
      );

      expect(result, Right<Failure, AppUser>(testUser));
      verify(
        () => authRepository.signInWithEmailLink(
          email: 'ada@example.com',
          emailLink: 'https://app.example.com/?oobCode=abc',
        ),
      ).called(1);
    });

    test('returns Left(AuthFailure) on an expired or invalid link', () async {
      when(
        () => authRepository.signInWithEmailLink(
          email: 'ada@example.com',
          emailLink: 'https://app.example.com/?oobCode=expired',
        ),
      ).thenAnswer(
        (_) async => const Left(AuthFailure('That sign-in link is invalid or has expired.')),
      );

      final result = await useCase(
        email: 'ada@example.com',
        emailLink: 'https://app.example.com/?oobCode=expired',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('Expected a Left(AuthFailure)'),
      );
    });
  });
}
