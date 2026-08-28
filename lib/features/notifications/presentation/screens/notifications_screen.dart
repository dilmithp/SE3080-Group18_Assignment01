import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/notifications/domain/entities/app_notification.dart';
import 'package:elderly_companion/features/notifications/domain/entities/notification_type.dart';
import 'package:elderly_companion/features/notifications/presentation/providers/notifications_providers.dart';

/// The signed-in user's notification feed, newest first. Unread items are
/// bold with a tinted background *and* carry a small dot — never colour
/// alone — so the distinction reads for colourblind users too.
///
/// Tapping a notification marks it read (fire-and-forget: the read-flag
/// write is not awaited before navigating, so a slow connection never
/// blocks the tap) and, for a session-related notification, opens that
/// session.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: userId == null
          ? const ErrorView(
              title: 'Not signed in',
              message: 'Sign in to see your notifications.',
            )
          : _NotificationsList(userId: userId),
    );
  }
}

class _NotificationsList extends ConsumerWidget {
  const _NotificationsList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsForUserProvider(userId));

    return notificationsAsync.when(
      loading: () => const LoadingView(message: 'Loading notifications…'),
      error: (error, _) => ErrorView(
        message: 'Something went wrong loading your notifications.',
        onRetry: () => ref.invalidate(notificationsForUserProvider(userId)),
      ),
      data: (notifications) {
        if (notifications.isEmpty) {
          return const EmptyView(
            icon: Icons.notifications_none,
            title: 'No notifications yet',
            message: "You'll see updates about your sessions here.",
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  _NotificationTile(notification: notifications[index]),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (!notification.isRead) {
      // Fire-and-forget: not awaited, so a slow or failed read-flag write
      // never blocks navigation. Safe to ignore the result — the use case
      // returns an Either rather than throwing, and there's nothing useful
      // to show the user for a background write they didn't initiate
      // directly.
      unawaited(ref.read(markNotificationReadUseCaseProvider).call(notification.id));
    }

    final relatedId = notification.relatedId;
    if (relatedId != null && notification.type.value.startsWith('session_')) {
      context.push(RouteNames.sessionDetailsPath(relatedId));
    }
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.sessionConfirmed:
        return Icons.event_available_outlined;
      case NotificationType.sessionCancelled:
        return Icons.event_busy_outlined;
      case NotificationType.sessionCompleted:
        return Icons.task_alt_outlined;
      case NotificationType.feedbackReceived:
        return Icons.star_outline;
      case NotificationType.verificationApproved:
        return Icons.verified_user_outlined;
      case NotificationType.verificationRejected:
        return Icons.error_outline;
      case NotificationType.other:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;
    final scheme = theme.colorScheme;

    return AppCard(
      onTap: () => _handleTap(context, ref),
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: isUnread ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
          borderRadius: AppRadius.smallAll,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUnread ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconFor(notification.type),
                size: 24,
                color: isUnread ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _relativeTime(notification.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
