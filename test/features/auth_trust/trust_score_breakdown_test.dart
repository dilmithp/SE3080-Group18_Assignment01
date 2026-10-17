import 'package:elderly_companion/features/auth_trust/domain/entities/trust_score.dart';
import 'package:elderly_companion/features/auth_trust/domain/services/trust_score_breakdown.dart';
import 'package:flutter_test/flutter_test.dart';

TrustScore _score({required int completed, required double rating}) {
  return TrustScore(
    userId: 'u1',
    score: 0,
    completedSessions: completed,
    averageRating: rating,
    lastUpdated: DateTime(2026, 10, 3),
  );
}

void main() {
  group('TrustScoreBreakdown', () {
    test('no score document gives zero points everywhere', () {
      final b = TrustScoreBreakdown.of(null);

      expect(b.completedSessions, 0);
      expect(b.sessionPoints, 0);
      expect(b.ratingPoints, 0);
      expect(b.total, 0);
      expect(b.hasRatings, isFalse);
    });

    test('5 points per completed session', () {
      final b = TrustScoreBreakdown.of(_score(completed: 4, rating: 0));

      expect(b.sessionPoints, 20);
      expect(b.total, 20);
    });

    test('rating adds 10 points per star of average rating', () {
      final b = TrustScoreBreakdown.of(_score(completed: 0, rating: 4.5));

      expect(b.ratingPoints, closeTo(45, 1e-9));
      expect(b.total, closeTo(45, 1e-9));
      expect(b.hasRatings, isTrue);
    });

    test('session and rating points add together', () {
      final b = TrustScoreBreakdown.of(_score(completed: 6, rating: 4.0));

      expect(b.sessionPoints, 30);
      expect(b.ratingPoints, 40);
      expect(b.total, 70);
      expect(b.isCapped, isFalse);
    });

    test('total is capped at 100 and reports that it was capped', () {
      final b = TrustScoreBreakdown.of(_score(completed: 20, rating: 5.0));

      expect(b.uncappedTotal, 150);
      expect(b.total, 100);
      expect(b.isCapped, isTrue);
    });

    test('exactly 100 is not reported as capped', () {
      final b = TrustScoreBreakdown.of(_score(completed: 10, rating: 5.0));

      expect(b.uncappedTotal, 100);
      expect(b.isCapped, isFalse);
    });
  });
}
