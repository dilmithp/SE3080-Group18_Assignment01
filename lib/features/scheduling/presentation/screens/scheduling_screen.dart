import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/core/widgets/skeleton_loader.dart';
import 'package:elderly_companion/core/widgets/staggered_entrance.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/presentation/providers/scheduling_providers.dart';

/// Owner: Ranketh (features/scheduling). Live list of the signed-in user's
/// sessions, wired to [SessionRepository.watchSessionsForUser].
class SchedulingScreen extends ConsumerWidget {
  const SchedulingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
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
          return _SessionList(userId: user.id);
        },
      ),
    );
  }
}

class _SessionList extends ConsumerWidget {
  const _SessionList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsForUserProvider(userId));
    final simplified = ref.watch(
      accessibilityControllerProvider.select((s) => s.simplifiedMode),
    );

    return sessionsAsync.when(
      loading: () => const SkeletonList(),
      error: (error, _) => ErrorView(message: error.toString()),
      data: (sessions) {
        if (sessions.isEmpty) {
          return const EmptyView(
            icon: Icons.event_available_outlined,
            title: 'No sessions booked',
            message: 'Once you arrange time with a companion, it will show '
                'up here with the date, place and who you are meeting.',
          );
        }
        final sorted = [...sessions]
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => StaggeredEntrance(
            index: index,
            child: _SessionCard(session: sorted[index], simplified: simplified),
          ),
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.simplified});

  final Session session;
  final bool simplified;

  ({Color background, Color foreground}) _statusColors(ColorScheme scheme) {
    return switch (session.status) {
      SessionStatus.requested => (
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
        ),
      SessionStatus.confirmed => (
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
        ),
      SessionStatus.completed => (
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        ),
      SessionStatus.cancelled => (
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _statusColors(theme.colorScheme);
    final formatted = DateFormat('EEE, d MMM · h:mm a').format(session.scheduledAt);

    return AppCard(
      onTap: () => context.push(RouteNames.sessionDetailsPath(session.id)),
      child: Row(
        children: [
          AppStatusIcon(
            icon: Icons.event_note_outlined,
            size: simplified ? 72 : 56,
            background: colors.background,
            foreground: colors.foreground,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatted,
                  style: simplified ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge,
                ),
                if (!simplified) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${session.location} · ${session.durationMinutes} min',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    session.status.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
