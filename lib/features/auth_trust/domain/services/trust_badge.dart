import 'package:elderly_companion/features/auth_trust/domain/entities/trust_score.dart';

/// Recognition tier shown on a profile/match card. Ordered low → high so
/// `.index` can be used for simple comparisons if ever needed.
enum TrustBadgeTier { newMember, bronze, silver, gold, platinum }

/// Maps a (possibly absent) [TrustScore] to a [TrustBadgeTier] and a
/// human-readable label.
///
/// Pure Dart and side-effect free — like [FeedbackEligibility], worth
/// testing on its own rather than only through a widget. `trust_scores/{userId}`
/// is written by a not-yet-implemented Cloud Function, so most users have no
/// document at all yet; `null` (and `completedSessions == 0`) are both
/// treated as the normal "new member" starting state, never as an error.
///
/// Tier thresholds, keyed on [TrustScore.completedSessions] as the primary
/// signal:
/// - `newMember` — no score yet, or 0 completed sessions
/// - `bronze` — 1 to 4 completed sessions
/// - `silver` — 5 to 14 completed sessions
/// - `gold` — 15 to 39 completed sessions
/// - `platinum` — 40 or more completed sessions
///
/// Owner: Pathirana (features/auth_trust).
class TrustBadge {
  const TrustBadge();

  /// The tier for [score]. `null` is treated the same as a score with zero
  /// completed sessions — a brand-new member, not an error state.
  TrustBadgeTier tierFor(TrustScore? score) {
    final completedSessions = score?.completedSessions ?? 0;
    if (completedSessions >= 40) return TrustBadgeTier.platinum;
    if (completedSessions >= 15) return TrustBadgeTier.gold;
    if (completedSessions >= 5) return TrustBadgeTier.silver;
    if (completedSessions >= 1) return TrustBadgeTier.bronze;
    return TrustBadgeTier.newMember;
  }

  /// Human-readable label for [tier], suitable for display directly on a
  /// badge chip.
  String labelFor(TrustBadgeTier tier) {
    switch (tier) {
      case TrustBadgeTier.newMember:
        return 'New member';
      case TrustBadgeTier.bronze:
        return 'Bronze volunteer';
      case TrustBadgeTier.silver:
        return 'Silver volunteer';
      case TrustBadgeTier.gold:
        return 'Gold volunteer';
      case TrustBadgeTier.platinum:
        return 'Platinum volunteer';
    }
  }
}
