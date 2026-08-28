import 'package:dartz/dartz.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/verification_request.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/verification_status.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/verification_repository.dart';
import 'package:elderly_companion/features/auth_trust/domain/usecases/review_verification_request_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mocks the abstract [VerificationRepository] interface (never a Firebase
/// implementation) per this repo's testing pattern — see
/// test/features/auth_trust/auth_repository_test.dart.
class MockVerificationRepository extends Mock implements VerificationRepository {}

void main() {
  late MockVerificationRepository verificationRepository;
  late ReviewVerificationRequestUseCase useCase;

  setUp(() {
    verificationRepository = MockVerificationRepository();
    useCase = ReviewVerificationRequestUseCase(verificationRepository);
  });

  final approvedRequest = VerificationRequest(
    id: 'request-1',
    userId: 'user-1',
    documentUrl: 'https://example.com/doc.jpg',
    status: VerificationStatus.approved,
    reviewedBy: 'admin-1',
    reviewedAt: DateTime(2026, 1, 2),
  );

  group('ReviewVerificationRequestUseCase', () {
    test('returns Right(VerificationRequest) on successful approval', () async {
      when(
        () => verificationRepository.reviewVerificationRequest(
          requestId: 'request-1',
          reviewerId: 'admin-1',
          approve: true,
        ),
      ).thenAnswer((_) async => Right(approvedRequest));

      final result = await useCase(
        requestId: 'request-1',
        reviewerId: 'admin-1',
        approve: true,
      );

      expect(result, Right<Failure, VerificationRequest>(approvedRequest));
      verify(
        () => verificationRepository.reviewVerificationRequest(
          requestId: 'request-1',
          reviewerId: 'admin-1',
          approve: true,
        ),
      ).called(1);
    });

    test('returns Left(Failure) when the repository call fails', () async {
      when(
        () => verificationRepository.reviewVerificationRequest(
          requestId: 'request-1',
          reviewerId: 'admin-1',
          approve: false,
        ),
      ).thenAnswer((_) async => const Left(NotFoundFailure('Verification request not found.')));

      final result = await useCase(
        requestId: 'request-1',
        reviewerId: 'admin-1',
        approve: false,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Expected a Left(NotFoundFailure)'),
      );
    });
  });
}
