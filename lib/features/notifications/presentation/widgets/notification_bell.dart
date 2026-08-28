import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/app_motion.dart';
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
      return const _BellButton(unreadCount: 0, reduceMotion: true);
    }
    if (userId == null) {
      // Signed out (or auth failed) — nothing to badge, nothing to open.
      return const SizedBox.shrink();
    }

    final unreadCount = ref.watch(unreadNotificationCountProvider(userId));

    return _BellButton(
      unreadCount: unreadCount,
      reduceMotion: AppMotion.reduced(context, ref),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unreadCount, required this.reduceMotion});

  final int unreadCount;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Doubles as the IconButton's accessibility label (IconButton falls
    // back to its tooltip when nothing more specific is given), so a
    // screen reader hears the unread count without a separate Semantics
    // wrapper.
    final tooltip =
        unreadCount > 0 ? 'Notifications, $unreadCount unread' : 'Notifications';

    final badge = Badge(
      isLabelVisible: unreadCount > 0,
      label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
      backgroundColor: theme.colorScheme.error,
      textColor: theme.colorScheme.onError,
      child: const Icon(Icons.notifications_outlined),
    );

    return IconButton(
      tooltip: tooltip,
      onPressed: () => context.push(RouteNames.notifications),
      // Re-keying on the count makes a fresh count arriving "pop" briefly
      // rather than silently changing the label — the one moment worth
      // calling out on an otherwise static icon.
      icon: reduceMotion
          ? badge
          : TweenAnimationBuilder<double>(
              key: ValueKey(unreadCount),
              tween: Tween(begin: unreadCount > 0 ? 1.35 : 1.0, end: 1.0),
              duration: AppMotion.fast,
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: badge,
            ),
    );
  }
}
