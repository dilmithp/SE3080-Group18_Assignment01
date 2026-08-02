import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/verification_request.dart';

/// Contract: identity-document upload and verification-approval workflow
/// only. Split from [AuthRepository] (Interface Segregation) so admin-only
/// approval flows don't leak into every screen that just needs to sign in.
///
/// Owner: Pathirana (features/auth_trust).
abstract class VerificationRepository {
  Future<Either<Failure, VerificationRequest>> submitVerificationRequest({
    required String userId,
    required String documentUrl,
  });

  Stream<VerificationRequest?> watchVerificationStatus(String userId);

  /// Admin-only: approves or rejects a pending request.
  Future<Either<Failure, VerificationRequest>> reviewVerificationRequest({
    required String requestId,
    required String reviewerId,
    required bool approve,
  });
}
