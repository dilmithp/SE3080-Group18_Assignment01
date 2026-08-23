import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/series_cancellation_result.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/services/session_series.dart';
import 'package:elderly_companion/features/scheduling/presentation/providers/scheduling_providers.dart';

/// Owner: Ranketh (features/scheduling). Every occurrence of one recurring
/// series, oldest first, with a way to call off the ones still to come.
///
/// A series has no document of its own — this is the sessions-for-user
/// stream filtered by `seriesId`, so it stays live as occurrences change.
class SessionSeriesScreen extends ConsumerWidget {
  const SessionSeriesScreen({required this.seriesId, super.key});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Repeating sessions')),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (user) {
          if (user == null) {
            return const EmptyView(
              icon: Icons.lock_outline,
              title: 'Sign in first',
              message: 'You need to be signed in to see your sessions.',
            );
          }
          return _SeriesBody(seriesId: seriesId, userId: user.id);
        },
      ),
    );
  }
}

class _SeriesBody extends ConsumerStatefulWidget {
  const _SeriesBody({required this.seriesId, required this.userId});

  final String seriesId;
  final String userId;

  @override
  ConsumerState<_SeriesBody> createState() => _SeriesBodyState();
}

class _SeriesBodyState extends ConsumerState<_SeriesBody> {
  bool _isCancelling = false;

  /// Cancels the rest of the series, after asking — `cancelled` is terminal,
  /// so there is no undo once this runs.
  Future<void> _cancelRemaining(List<Session> occurrences) async {
    final messenger = ScaffoldMessenger.of(context);
    final remaining = const SessionSeries().cancellableOccurrences(occurrences);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel remaining sessions?'),
        content: Text(
          remaining.length == 1
              ? 'One session in this series has not happened yet. It will be '
                  'cancelled and cannot be brought back.'
              : '${remaining.length} sessions in this series have not '
                  'happened yet. They will be cancelled and cannot be '
                  'brought back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep them'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel them'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      final useCase = ref.read(cancelSeriesUseCaseProvider);
      final result = await useCase(
        seriesId: widget.seriesId,
        occurrences: occurrences,
      );
      result.fold(
        (failure) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message))),
        (cancellation) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(seriesCancellationMessage(cancellation))),
          ),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(
      sessionSeriesProvider((userId: widget.userId, seriesId: widget.seriesId)),
    );
    final simplified = ref.watch(
      accessibilityControllerProvider.select((s) => s.simplifiedMode),
    );

    return seriesAsync.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(message: error.toString()),
      data: (occurrences) {
        if (occurrences.isEmpty) {
          return const EmptyView(
            icon: Icons.repeat,
            title: 'Series not found',
            message: 'These repeating sessions may have been removed, or they '
                'belong to someone else.',
          );
        }

        final canCancel =
            const SessionSeries().hasCancellableOccurrences(occurrences);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SeriesSummary(occurrences: occurrences, simplified: simplified),
                  const SizedBox(height: AppSpacing.md),
                  for (final occurrence in occurrences) ...[
                    _OccurrenceCard(
                      occurrence: occurrence,
                      simplified: simplified,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  if (canCancel)
                    AppButton(
                      label: 'Cancel remaining sessions',
                      icon: Icons.event_busy_outlined,
                      secondary: true,
                      isLoading: _isCancelling,
                      onPressed: () => _cancelRemaining(occurrences),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeriesSummary extends StatelessWidget {
  const _SeriesSummary({required this.occurrences, required this.simplified});

  final List<Session> occurrences;
  final bool simplified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = occurrences.first;
    final upcoming =
        const SessionSeries().cancellableOccurrences(occurrences).length;

    return AppCard(
      child: Row(
        children: [
          AppStatusIcon(
            icon: Icons.repeat,
            size: simplified ? 88 : 64,
            background: theme.colorScheme.tertiaryContainer,
            foreground: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${occurrences.length} sessions in this series',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  upcoming == 0
                      ? 'None still to come'
                      : '$upcoming still to come',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!simplified) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(first.location, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OccurrenceCard extends StatelessWidget {
  const _OccurrenceCard({required this.occurrence, required this.simplified});

  final Session occurrence;
  final bool simplified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted =
        DateFormat('EEEE, d MMMM · h:mm a').format(occurrence.scheduledAt);

    return AppCard(
      onTap: () => context.push(RouteNames.sessionDetailsPath(occurrence.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatted, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  occurrence.status.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!simplified)
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// What to tell someone after cancelling the rest of a series.
///
/// A partial run gets its own wording for the same reason
/// [recurringBookingMessage] does: claiming success over a failed write
/// would leave a session on the calendar that the person believes is gone.
///
/// Pure — no [BuildContext] — so the wording is unit-testable.
String seriesCancellationMessage(SeriesCancellationResult result) {
  if (result.nothingToCancel) {
    return 'Nothing left to cancel — these sessions have already finished '
        'or been cancelled.';
  }

  final cancelled = result.cancelledSessions.length;
  if (result.isComplete) {
    return cancelled == 1
        ? 'Session cancelled.'
        : 'Cancelled $cancelled sessions.';
  }

  final failed = result.failedSessionIds.length;
  return 'Cancelled $cancelled of ${result.attemptedCount} sessions — '
      '$failed could not be cancelled and ${failed == 1 ? 'is' : 'are'} '
      'still booked. Please try again.';
}
