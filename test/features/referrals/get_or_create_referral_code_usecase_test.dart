import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/referrals/domain/entities/referral_code.dart';
import 'package:elderly_companion/features/referrals/domain/repositories/referral_repository.dart';
import 'package:elderly_companion/features/referrals/domain/usecases/get_or_create_referral_code_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract [ReferralRepository] interface (never the Firebase
/// implementation) — see test/features/auth_trust/auth_repository_test.dart
/// for the canonical shape this copies.
class MockReferralRepository extends Mock implements ReferralRepository {}

void main() {
  late MockReferralRepository repository;
  late GetOrCreateReferralCodeUseCase useCase;

  setUp(() {
    repository = MockReferralRepository();
    useCase = GetOrCreateReferralCodeUseCase(repository);
  });

  final testCode = ReferralCode(
    code: '7K9P2M',
    ownerId: 'user-1',
    createdAt: DateTime(2026, 1, 1),
  );

  group('GetOrCreateReferralCodeUseCase', () {
    test('delegates to the repository and returns Right(ReferralCode) on success', () async {
      when(() => repository.getOrCreateMyCode('user-1'))
          .thenAnswer((_) async => Right(testCode));

      final result = await useCase('user-1');

      expect(result, Right<Failure, ReferralCode>(testCode));
      verify(() => repository.getOrCreateMyCode('user-1')).called(1);
    });

    test('returns Left(Failure) when the repository fails', () async {
      when(() => repository.getOrCreateMyCode('user-1'))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase('user-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected a Left(NetworkFailure)'),
      );
    });
  });
}
