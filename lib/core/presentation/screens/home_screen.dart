import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/routing/app_router.dart';
import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';

/// Post-login dashboard. Shell screen owned by no single feature — it just
/// links out to each feature's placeholder screen and exposes the
/// accessibility controls every screen inherits.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilityControllerProvider);
    final controller = ref.read(accessibilityControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elderly Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () {
              ref.read(isAuthenticatedProvider.notifier).state = false;
              context.go(RouteNames.login);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NavTile(
            icon: Icons.person_outline,
            title: 'My profile',
            subtitle: 'View and edit your details',
            onTap: () => context.push(RouteNames.profile),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.handshake_outlined,
            title: 'Find a match',
            subtitle: 'Companions and helpers near you',
            onTap: () => context.push(RouteNames.matching),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.event_available_outlined,
            title: 'Sessions',
            subtitle: 'Bookings and schedule',
            onTap: () => context.push(RouteNames.scheduling),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.verified_user_outlined,
            title: 'Verification',
            subtitle: 'Trust & safety status',
            onTap: () => context.push(RouteNames.verification),
          ),
          const SizedBox(height: 24),
          Text('Accessibility', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('High contrast'),
                  value: accessibility.highContrast,
                  onChanged: controller.setHighContrast,
                ),
                SwitchListTile(
                  title: const Text('Simplified mode'),
                  value: accessibility.simplifiedMode,
                  onChanged: controller.setSimplifiedMode,
                ),
                ListTile(
                  title: const Text('Text size'),
                  subtitle: Slider(
                    value: accessibility.textScale,
                    min: 0.85,
                    max: 1.6,
                    divisions: 15,
                    label: '${(accessibility.textScale * 100).round()}%',
                    onChanged: controller.setTextScale,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
