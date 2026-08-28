import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_state.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/staggered_entrance.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/notifications/presentation/widgets/notification_bell.dart';

/// Post-login dashboard. Shell screen owned by no single feature — it just
/// links out to each feature's placeholder screen and exposes the
/// accessibility controls every screen inherits.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elderly Companion'),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go(RouteNames.login);
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: const [
              _Greeting(),
              SizedBox(height: AppSpacing.lg),
              _SectionHeader('What would you like to do?'),
              SizedBox(height: AppSpacing.sm),
              _NavTiles(),
              SizedBox(height: AppSpacing.xl),
              _SectionHeader('Accessibility'),
              SizedBox(height: AppSpacing.sm),
              _AccessibilityPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back', style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pick up where you left off, or start something new.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _NavTiles extends StatelessWidget {
  const _NavTiles();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StaggeredEntrance(
          index: 0,
          child: _NavTile(
            icon: Icons.person_outline,
            title: 'My profile',
            subtitle: 'View and edit your details',
            tone: _Tone.primary,
            onTap: () => context.push(RouteNames.profile),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StaggeredEntrance(
          index: 1,
          child: _NavTile(
            icon: Icons.handshake_outlined,
            title: 'Find a match',
            subtitle: 'Companions and helpers near you',
            tone: _Tone.tertiary,
            onTap: () => context.push(RouteNames.matching),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StaggeredEntrance(
          index: 2,
          child: _NavTile(
            icon: Icons.event_available_outlined,
            title: 'Sessions',
            subtitle: 'Your bookings and schedule',
            tone: _Tone.primary,
            onTap: () => context.push(RouteNames.scheduling),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StaggeredEntrance(
          index: 3,
          child: _NavTile(
            icon: Icons.verified_user_outlined,
            title: 'Verification',
            subtitle: 'Trust and safety status',
            tone: _Tone.secondary,
            onTap: () => context.push(RouteNames.verification),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StaggeredEntrance(
          index: 4,
          child: _NavTile(
            icon: Icons.chat_bubble_outline,
            title: 'Messages',
            subtitle: 'Chat with your matches',
            tone: _Tone.secondary,
            onTap: () => context.push(RouteNames.conversations),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StaggeredEntrance(
          index: 5,
          child: _NavTile(
            icon: Icons.forum_outlined,
            title: 'Community',
            subtitle: 'Thank-yous, updates and requests',
            tone: _Tone.tertiary,
            onTap: () => context.push(RouteNames.community),
          ),
        ),
        Consumer(
          builder: (context, ref, _) {
            final role = ref.watch(authStateProvider).valueOrNull?.role;
            if (role != UserRole.admin) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                StaggeredEntrance(
                  index: 6,
                  child: _NavTile(
                    icon: Icons.fact_check_outlined,
                    title: 'Verification queue',
                    subtitle: 'Review pending identity documents',
                    tone: _Tone.primary,
                    onTap: () => context.push(RouteNames.adminVerificationQueue),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Which container role tints a tile's icon badge. Rotating between them
/// gives the dashboard colour variety — and the warm terracotta is what keeps
/// it from reading as a utility app.
enum _Tone { primary, secondary, tertiary }

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _Tone tone;
  final VoidCallback onTap;

  ({Color background, Color foreground}) _colors(ColorScheme scheme) {
    return switch (tone) {
      _Tone.primary => (
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
        ),
      _Tone.secondary => (
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        ),
      _Tone.tertiary => (
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _colors(theme.colorScheme);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: AppRadius.smallAll,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 30, color: colors.foreground),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _AccessibilityPanel extends ConsumerWidget {
  const _AccessibilityPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilityControllerProvider);
    final controller = ref.read(accessibilityControllerProvider.notifier);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('High contrast'),
            subtitle: const Text('Stronger colours and bolder outlines'),
            value: accessibility.highContrast,
            onChanged: controller.setHighContrast,
          ),
          const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
          SwitchListTile(
            title: const Text('Simplified mode'),
            subtitle: const Text('Fewer things on screen at once'),
            value: accessibility.simplifiedMode,
            onChanged: controller.setSimplifiedMode,
          ),
          const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
          _TextSizeControl(
            value: accessibility.textScale,
            onChanged: controller.setTextScale,
          ),
        ],
      ),
    );
  }
}

class _TextSizeControl extends StatelessWidget {
  const _TextSizeControl({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Text size', style: theme.textTheme.bodyLarge),
              ),
              Text(
                '${(value * 100).round()}%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // The two glyphs are a live preview: they scale with the value
              // the slider is setting, so the effect is visible before the
              // user leaves this screen.
              Icon(Icons.text_decrease, color: theme.colorScheme.onSurfaceVariant),
              Expanded(
                child: Slider(
                  value: value,
                  min: AccessibilityState.minTextScale,
                  max: AccessibilityState.maxTextScale,
                  divisions: 15,
                  label: '${(value * 100).round()}%',
                  onChanged: onChanged,
                ),
              ),
              Icon(Icons.text_increase, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}
