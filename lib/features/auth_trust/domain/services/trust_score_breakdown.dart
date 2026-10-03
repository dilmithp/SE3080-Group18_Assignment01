import 'dart:math' as math;

import 'package:elderly_companion/features/auth_trust/domain/entities/trust_score.dart';

/// Explains how a [TrustScore] is built. The constants mirror
/// `recomputeTrustScoreFor` in functions/index.js: keep them in sync if the
/// Cloud Function formula changes.
///
/// Verification status is not part of the score, so it is not part of this
/// breakdown either.
///
/// Pure Dart, no Firebase or Flutter imports.
class TrustScoreBreakdown {
  const TrustScoreBreakdown._({
    required this.completedSessions,
    required this.averageRating,
  });

  factory TrustScoreBreakdown.of(TrustScore? score) {
    return TrustScoreBreakdown._(
      completedSessions: score?.completedSessions ?? 0,
      averageRating: score?.averageRating ?? 0,
    );
  }

  static const double pointsPerCompletedSession = 5;
  static const double pointsPerRatingPoint = 10;
  static const double maxScore = 100;

  final int completedSessions;
  final double averageRating;

  double get sessionPoints => completedSessions * pointsPerCompletedSession;

  double get ratingPoints => averageRating * pointsPerRatingPoint;

  double get uncappedTotal => sessionPoints + ratingPoints;

  double get total => math.min(maxScore, uncappedTotal);

  bool get isCapped => uncappedTotal > maxScore;

  bool get hasRatings => averageRating > 0;
}
