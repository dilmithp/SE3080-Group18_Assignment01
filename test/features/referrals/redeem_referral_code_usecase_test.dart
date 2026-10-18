import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/referrals/domain/entities/referral.dart';
import 'package:elderly_companion/features/referrals/domain/repositories/referral_repository.dart';
import 'package:elderly_companion/features/referrals/domain/usecases/redeem_referral_code_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract [ReferralRepository] interface (never the Firebase
/// implementation) — see test/features/auth_trust/auth_repository_test.dart
/// for the canonical shape this copies.
class MockReferralRepository extends Mock implements ReferralRepository {}

void main() {
  late MockReferralRepository repository;
  late RedeemReferralCodeUseCase useCase;

  setUp(() {
    repository = MockReferralRepository();
    useCase = RedeemReferralCodeUseCase(repository);
  });

  final testReferral = Referral(
    id: 'user-2',
    code: '7K9P2M',
    referrerId: 'user-1',
    referredUserId: 'user-2',
    referredName: 'Sam',
    createdAt: DateTime(2026, 1, 1),
  );

  group('RedeemReferralCodeUseCase', () {
    test('delegates to the repository and returns Right(Referral) on success', () async {
      when(
        () => repository.redeemCode(
          code: '7K9P2M',
          referredUserId: 'user-2',
          referredName: 'Sam',
        ),
      ).thenAnswer((_) async => Right(testReferral));

      final result = await useCase(
        code: '7K9P2M',
        referredUserId: 'user-2',
        referredName: 'Sam',
      );

      expect(result, Right<Failure, Referral>(testReferral));
      verify(
        () => repository.redeemCode(
          code: '7K9P2M',
          referredUserId: 'user-2',
          referredName: 'Sam',
        ),
      ).called(1);
    });

    test('returns Left(NotFoundFailure) for an unknown code', () async {
      when(
        () => repository.redeemCode(
          code: 'BADCOD',
          referredUserId: 'user-2',
          referredName: 'Sam',
        ),
      ).thenAnswer(
        (_) async => const Left(NotFoundFailure('That referral code is not valid.')),
      );

      final result = await useCase(
        code: 'BADCOD',
        referredUserId: 'user-2',
        referredName: 'Sam',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Expected a Left(NotFoundFailure)'),
      );
    });

    test('returns Left(PermissionFailure) when redeeming a second time', () async {
      when(
        () => repository.redeemCode(
          code: '7K9P2M',
          referredUserId: 'user-2',
          referredName: 'Sam',
        ),
      ).thenAnswer(
        (_) async =>
            const Left(PermissionFailure('You have already used a referral code.')),
      );

      final result = await useCase(
        code: '7K9P2M',
        referredUserId: 'user-2',
        referredName: 'Sam',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<PermissionFailure>()),
        (_) => fail('Expected a Left(PermissionFailure)'),
      );
    });
  });
}
