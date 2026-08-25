import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/notifications/presentation/providers/notifications_providers.dart';

/// Small bell icon meant to sit in an [AppBar.actions], showing a red badge
/// with the signed-in user's unread notification count. Renders nothing
/// when nobody is signed in, and a plain bell (no badge) while auth/the
/// notification feed is still loading — never a spinner, so it doesn't
/// compete with the rest of the app bar for attention.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userId = authState.valueOrNull?.id;

    if (authState.isLoading && !authState.hasValue) {
      return const _BellButton(unreadCount: 0);
    }
    if (userId == null) {
      // Signed out (or auth failed) — nothing to badge, nothing to open.
      return const SizedBox.shrink();
    }

    final unreadCount = ref.watch(unreadNotificationCountProvider(userId));

    return _BellButton(unreadCount: unreadCount);
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Doubles as the IconButton's accessibility label (IconButton falls
    // back to its tooltip when nothing more specific is given), so a
    // screen reader hears the unread count without a separate Semantics
    // wrapper.
    final tooltip =
        unreadCount > 0 ? 'Notifications, $unreadCount unread' : 'Notifications';

    return IconButton(
      tooltip: tooltip,
      onPressed: () => context.push(RouteNames.notifications),
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
        backgroundColor: theme.colorScheme.error,
        textColor: theme.colorScheme.onError,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
