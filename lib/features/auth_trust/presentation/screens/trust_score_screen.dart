import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/features/auth_trust/domain/services/trust_score_breakdown.dart';
import 'package:elderly_companion/features/auth_trust/presentation/widgets/trust_badge_chip.dart';

/// Shows how [userId]'s trust score is built: completed sessions, average
/// rating, and the 100-point cap. Reads only; nothing here writes a score.
///
/// Owner: Pathirana (features/auth_trust).
class TrustScoreScreen extends ConsumerWidget {
  const TrustScoreScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(watchTrustScoreProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Why this trust score?')),
      body: scoreAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (score) {
          final breakdown = TrustScoreBreakdown.of(score);
          final theme = Theme.of(context);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your score is ${breakdown.total.toStringAsFixed(0)} out of 100',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(child: TrustBadgeChip(trustScore: score)),
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Completed sessions', style: theme.textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${breakdown.completedSessions} completed × '
                            '${TrustScoreBreakdown.pointsPerCompletedSession.toStringAsFixed(0)} '
                            'points = ${breakdown.sessionPoints.toStringAsFixed(0)} points',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Average rating', style: theme.textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            breakdown.hasRatings
                                ? '${breakdown.averageRating.toStringAsFixed(1)} out of 5 × '
                                    '${TrustScoreBreakdown.pointsPerRatingPoint.toStringAsFixed(0)} '
                                    'points = ${breakdown.ratingPoints.toStringAsFixed(0)} points'
                                : 'No ratings yet, so this adds 0 points.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: theme.textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            breakdown.isCapped
                                ? 'Points add up to ${breakdown.uncappedTotal.toStringAsFixed(0)}, '
                                    'but the score is capped at 100.'
                                : '${breakdown.sessionPoints.toStringAsFixed(0)} + '
                                    '${breakdown.ratingPoints.toStringAsFixed(0)} = '
                                    '${breakdown.total.toStringAsFixed(0)} points.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Verification does not change this score. The score updates '
                      'when a session is completed or feedback is left.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
