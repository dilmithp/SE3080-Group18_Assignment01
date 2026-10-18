import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/sos/domain/entities/sos_alert.dart';
import 'package:elderly_companion/features/sos/presentation/providers/sos_providers.dart';

/// Admin-only live queue of every active [SosAlert], across all users —
/// the reviewer-facing counterpart to [SosButton]. Same defense-in-depth
/// shape as [AdminVerificationQueueScreen]: the real enforcement is
/// `firestore.rules` (`allow read: if isOwner(...) || isAdmin();` on
/// `sos_alerts`), this screen is just the UX guard.
class ActiveSosAlertsScreen extends ConsumerWidget {
  const ActiveSosAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Active SOS alerts')),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (user) {
          if (user == null || user.role != UserRole.admin) {
            return const EmptyView(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admins only',
              message: 'You need an admin account to view SOS alerts.',
            );
          }
          return const _AlertList();
        },
      ),
    );
  }
}

class _AlertList extends ConsumerWidget {
  const _AlertList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(activeSosAlertsProvider);
    final userId = ref.watch(authStateProvider).valueOrNull?.id;

    return alertsAsync.when(
      loading: () => const LoadingView(message: 'Loading active alerts...'),
      error: (error, _) => ErrorView(message: error.toString()),
      data: (alerts) {
        if (alerts.isEmpty) {
          return const EmptyView(
            icon: Icons.shield_outlined,
            title: 'No active alerts',
            message: 'Any SOS alert a user sends will appear here instantly.',
          );
        }
        return ListView.separated(
          padding: AppSpacing.screen,
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _AlertCard(
              alert: alert,
              onResolve: userId == null
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await ref.read(resolveSosAlertUseCaseProvider)(
                        alertId: alert.id,
                        resolvedBy: userId,
                      );
                      result.fold(
                        (failure) => messenger.showSnackBar(
                          SnackBar(content: Text(failure.message)),
                        ),
                        (_) => messenger.showSnackBar(
                          const SnackBar(content: Text('Alert marked resolved.')),
                        ),
                      );
                    },
            );
          },
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onResolve});

  final SosAlert alert;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = DateFormat('MMM d, HH:mm').format(alert.triggeredAt);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency, color: Colors.red),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Alert from ${alert.userId}',
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(timeLabel, style: theme.textTheme.bodySmall),
            ],
          ),
          if (alert.note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(alert.note!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (alert.hasLocation)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View location'),
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://maps.google.com/?q=${alert.latitude},${alert.longitude}',
                      ),
                    ),
                  ),
                )
              else
                const Expanded(
                  child: Text('No location available', textAlign: TextAlign.center),
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Resolve'),
                  onPressed: onResolve,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
