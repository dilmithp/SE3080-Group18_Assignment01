import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/app_user.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Example pattern for the rest of the team: mock the abstract repository
/// interface (never the Firebase implementation), stub the method under
/// test, and assert against the domain-level result. Once a real use case
/// exists that consumes [AuthRepository], test the use case against this
/// mock the same way — copy this file's shape.
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
  });

  final testUser = AppUser(
    id: 'user-1',
    email: 'ada@example.com',
    phone: '+94771234567',
    role: UserRole.volunteer,
    isVerified: false,
    createdAt: DateTime(2026, 1, 1),
  );

  group('AuthRepository (mocktail example)', () {
    test('signInWithEmail returns Right(AppUser) on success', () async {
      when(
        () => authRepository.signInWithEmail(
          email: 'ada@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => Right(testUser));

      final result = await authRepository.signInWithEmail(
        email: 'ada@example.com',
        password: 'password123',
      );

      expect(result, Right(testUser));
      verify(
        () => authRepository.signInWithEmail(
          email: 'ada@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('signInWithEmail returns Left(AuthFailure) on bad credentials', () async {
      when(
        () => authRepository.signInWithEmail(
          email: 'ada@example.com',
          password: 'wrong-password',
        ),
      ).thenAnswer((_) async => const Left(AuthFailure('Invalid credentials.')));

      final result = await authRepository.signInWithEmail(
        email: 'ada@example.com',
        password: 'wrong-password',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('Expected a Left(AuthFailure)'),
      );
    });
  });
}
