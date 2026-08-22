import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_state.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';

/// Screen allowing elderly users and volunteers to customize accessibility preferences:
/// - Dynamic Text Scaling (0.85x to 1.6x slider & quick presets)
/// - High Contrast Mode toggle
/// - Simplified Interface Mode toggle
/// - Voice-Guided Prompts toggle
///
/// Every change also writes through to the signed-in user's persisted
/// `UserProfile.accessibilityPrefs` (best-effort, silently skipped if not
/// signed in or no profile exists yet) so it follows them to a new device —
/// see AccessibilityProfileSync for the seed-on-sign-in half of that sync.
/// `voiceGuidedPrompts` has no persisted counterpart and stays local-only.
class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  static Future<void> _writeThrough(WidgetRef ref, AccessibilityState state) async {
    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;
    final profile = await ref.read(profileProvider(userId).future);
    if (profile == null) return;
    await ref.read(updateProfileUseCaseProvider)(
      profile.copyWith(
        accessibilityPrefs: profile.accessibilityPrefs.copyWith(
          highContrast: state.highContrast,
          simplifiedInterface: state.simplifiedMode,
          largeText: state.textScale > 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilityControllerProvider);
    final controller = ref.read(accessibilityControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, accessibility),
          const SizedBox(height: 16),
          _buildTextScaleCard(context, ref, accessibility, controller),
          const SizedBox(height: 16),
          _buildDisplayCard(context, ref, accessibility, controller),
          const SizedBox(height: 16),
          _buildVoiceGuidanceCard(context, accessibility, controller),
          const SizedBox(height: 24),
          AppButton(
            label: 'Reset Accessibility Defaults',
            secondary: true,
            onPressed: () async {
              await controller.setTextScale(1.0);
              await controller.setHighContrast(false);
              await controller.setSimplifiedMode(false);
              await controller.setVoiceGuidedPrompts(false);
              await _writeThrough(ref, ref.read(accessibilityControllerProvider));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Accessibility preferences reset to default.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AccessibilityState accessibility) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Accessibility Preferences Header',
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.accessibility_new,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customize Your Experience',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adjust text sizes, screen contrast, and navigation to best fit your comfort.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextScaleCard(
    BuildContext context,
    WidgetRef ref,
    AccessibilityState state,
    AccessibilityController controller,
  ) {
    final theme = Theme.of(context);
    final scalePercent = (state.textScale * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_size, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Text Size ($scalePercent%)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Preview text size below:',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              'Elderly Companionship & Micro-Volunteering platform text preview.',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * state.textScale,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: state.textScale,
            min: AccessibilityState.minTextScale,
            max: AccessibilityState.maxTextScale,
            divisions: 5,
            label: '$scalePercent%',
            onChanged: (val) async {
              await controller.setTextScale(val);
              await _writeThrough(ref, ref.read(accessibilityControllerProvider));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await controller.setTextScale(1.0);
                    await _writeThrough(ref, ref.read(accessibilityControllerProvider));
                  },
                  child: const Text('Standard'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await controller.setTextScale(1.3);
                    await _writeThrough(ref, ref.read(accessibilityControllerProvider));
                  },
                  child: const Text('Large'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await controller.setTextScale(1.5);
                    await _writeThrough(ref, ref.read(accessibilityControllerProvider));
                  },
                  child: const Text('Extra Large'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayCard(
    BuildContext context,
    WidgetRef ref,
    AccessibilityState state,
    AccessibilityController controller,
  ) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display & Layout',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('High Contrast Mode'),
            subtitle: const Text(
              'Increases text and button contrast for higher readability.',
            ),
            value: state.highContrast,
            onChanged: (enabled) async {
              await controller.setHighContrast(enabled);
              await _writeThrough(ref, ref.read(accessibilityControllerProvider));
            },
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Simplified Interface'),
            subtitle: const Text(
              'Reduces visual clutter and enlarges touch controls.',
            ),
            value: state.simplifiedMode,
            onChanged: (enabled) async {
              await controller.setSimplifiedMode(enabled);
              await _writeThrough(ref, ref.read(accessibilityControllerProvider));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceGuidanceCard(
    BuildContext context,
    AccessibilityState state,
    AccessibilityController controller,
  ) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assistance & Audio',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Voice-Guided Prompts'),
            subtitle: const Text(
              'Announce spoken guidance hints for screen actions and forms.',
            ),
            value: state.voiceGuidedPrompts,
            onChanged: (enabled) => controller.setVoiceGuidedPrompts(enabled),
          ),
        ],
      ),
    );
  }
}
