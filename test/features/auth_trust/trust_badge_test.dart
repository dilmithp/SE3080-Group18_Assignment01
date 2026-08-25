import 'package:elderly_companion/features/auth_trust/domain/entities/trust_score.dart';
import 'package:elderly_companion/features/auth_trust/domain/services/trust_badge.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-domain tests for [TrustBadge.tierFor] — the same shape as
/// test/features/scheduling/feedback_eligibility_test.dart. Every tier
/// boundary is pinned here rather than only exercised through a widget.
void main() {
  const badge = TrustBadge();

  TrustScore scoreWith(int completedSessions) => TrustScore(
        userId: 'user-1',
        score: 0,
        completedSessions: completedSessions,
        averageRating: 0,
        lastUpdated: DateTime(2026, 1, 1),
      );

  group('tierFor', () {
    test('null score (no trust_scores document yet) is newMember', () {
      expect(badge.tierFor(null), TrustBadgeTier.newMember);
    });

    test('0 completed sessions is newMember', () {
      expect(badge.tierFor(scoreWith(0)), TrustBadgeTier.newMember);
    });

    test('1 completed session is bronze (lower boundary)', () {
      expect(badge.tierFor(scoreWith(1)), TrustBadgeTier.bronze);
    });

    test('4 completed sessions is still bronze (upper boundary)', () {
      expect(badge.tierFor(scoreWith(4)), TrustBadgeTier.bronze);
    });

    test('5 completed sessions is silver (lower boundary)', () {
      expect(badge.tierFor(scoreWith(5)), TrustBadgeTier.silver);
    });

    test('14 completed sessions is still silver (upper boundary)', () {
      expect(badge.tierFor(scoreWith(14)), TrustBadgeTier.silver);
    });

    test('15 completed sessions is gold (lower boundary)', () {
      expect(badge.tierFor(scoreWith(15)), TrustBadgeTier.gold);
    });

    test('39 completed sessions is still gold (upper boundary)', () {
      expect(badge.tierFor(scoreWith(39)), TrustBadgeTier.gold);
    });

    test('40 completed sessions is platinum (lower boundary)', () {
      expect(badge.tierFor(scoreWith(40)), TrustBadgeTier.platinum);
    });

    test('well beyond 40 completed sessions is still platinum', () {
      expect(badge.tierFor(scoreWith(500)), TrustBadgeTier.platinum);
    });
  });

  group('labelFor', () {
    test('every tier has a distinct, human-readable label', () {
      final labels = TrustBadgeTier.values.map(badge.labelFor).toSet();
      expect(labels.length, TrustBadgeTier.values.length);
      expect(badge.labelFor(TrustBadgeTier.newMember), 'New member');
      expect(badge.labelFor(TrustBadgeTier.bronze), 'Bronze volunteer');
      expect(badge.labelFor(TrustBadgeTier.silver), 'Silver volunteer');
      expect(badge.labelFor(TrustBadgeTier.gold), 'Gold volunteer');
      expect(badge.labelFor(TrustBadgeTier.platinum), 'Platinum volunteer');
    });
  });
}
