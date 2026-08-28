import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/trust_score.dart';
import 'package:elderly_companion/features/auth_trust/domain/services/trust_badge.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';

/// Live trust score for [userId], for [TrustBadgeChip] call sites to watch
/// without polling. Colocated here (rather than in `auth_providers.dart`)
/// because this is the first client-facing consumer of
/// [TrustScoreRepository.watchTrustScore] — it just wires the existing
/// [trustScoreRepositoryProvider] the same way `verificationStatusProvider`
/// wires [VerificationRepository].
///
/// `trust_scores/{userId}` may not exist yet for most users (see
/// [TrustBadge]'s doc comment) — that surfaces here as a `null` value, a
/// normal state, not an [AsyncError].
final watchTrustScoreProvider =
    StreamProvider.family<TrustScore?, String>((ref, userId) {
  return ref.watch(trustScoreRepositoryProvider).watchTrustScore(userId);
});

/// Small pill showing a user's recognition tier (see [TrustBadge]), with an
/// icon + label per tier so the meaning never rests on color alone.
///
/// Takes a nullable [TrustScore] directly rather than a userId/provider, so
/// it can be dropped into any screen that already has a [TrustScore] (or
/// knows it has none yet) in hand — callers watch [watchTrustScoreProvider]
/// (or reuse an existing trust-score read) and pass the result through.
class TrustBadgeChip extends StatelessWidget {
  const TrustBadgeChip({required this.trustScore, super.key});

  final TrustScore? trustScore;

  static const _badge = TrustBadge();

  _TierVisuals _visualsFor(TrustBadgeTier tier, ColorScheme scheme) {
    switch (tier) {
      case TrustBadgeTier.newMember:
        return _TierVisuals(
          icon: Icons.emoji_people_outlined,
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurfaceVariant,
        );
      case TrustBadgeTier.bronze:
        return _TierVisuals(
          icon: Icons.military_tech_outlined,
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
        );
      case TrustBadgeTier.silver:
        return _TierVisuals(
          icon: Icons.military_tech,
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        );
      case TrustBadgeTier.gold:
        return _TierVisuals(
          icon: Icons.workspace_premium_outlined,
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
        );
      case TrustBadgeTier.platinum:
        return _TierVisuals(
          icon: Icons.workspace_premium,
          background: scheme.primary,
          foreground: scheme.onPrimary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = _badge.tierFor(trustScore);
    final label = _badge.labelFor(tier);
    final visuals = _visualsFor(tier, theme.colorScheme);

    return Semantics(
      label: 'Trust badge: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: visuals.background,
          borderRadius: AppRadius.pillAll,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(visuals.icon, size: 18, color: visuals.foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: visuals.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _TierVisuals {
  const _TierVisuals({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}
