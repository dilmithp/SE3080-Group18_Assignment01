import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/trust_score.dart';

/// Contract: trust-score reads only. Split from [AuthRepository] (Interface
/// Segregation) — a profile card that just displays a score should not
/// depend on sign-in/verification methods it will never call.
///
/// Owner: Pathirana (features/auth_trust). Score is written by a Cloud
/// Function after session completion/feedback, not by the client.
abstract class TrustScoreRepository {
  Future<Either<Failure, TrustScore>> getTrustScore(String userId);

  Stream<TrustScore?> watchTrustScore(String userId);
}
