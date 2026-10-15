import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/services/tts_provider.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_state.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/accessibility_profile_sync.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';

/// Screen allowing elderly users and volunteers to customize accessibility preferences:
/// - Dynamic Text Scaling (0.85x to 1.6x slider & quick presets)
/// - High Contrast Mode toggle
/// - Simplified Interface Mode toggle
/// - Reduced Motion toggle (independent from OS setting)
/// - Voice-Guided Prompts toggle (wired to [TtsService])
/// - Data Saver toggle
/// - Language picker (English / Sinhala / Tamil)
///
/// Every change also writes through to the signed-in user's persisted
/// `UserProfile.accessibilityPrefs` (best-effort, silently skipped if not
/// signed in or no profile exists yet) so it follows them to a new device —
/// see AccessibilityProfileSync for the seed-on-sign-in half of that sync.
class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  static Future<void> _writeThrough(WidgetRef ref, AccessibilityState state) async {
    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;
    final profile = await ref.read(profileProvider(userId).future);
    if (profile == null) return;
    await ref.read(updateProfileUseCaseProvider)(
      profile.copyWith(
        accessibilityPrefs:
            mapAccessibilityStateToPreferences(state, profile.accessibilityPrefs),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilityControllerProvider);
    final controller = ref.read(accessibilityControllerProvider.notifier);

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
          _buildVoiceGuidanceCard(context, ref, accessibility, controller),
          const SizedBox(height: 16),
          _buildLanguageCard(context, ref, accessibility, controller),
          const SizedBox(height: 24),
          Semantics(
            label: 'Reset all accessibility preferences to default',
            button: true,
            child: AppButton(
              label: 'Reset Accessibility Defaults',
              secondary: true,
              onPressed: () async {
                await controller.setTextScale(1.0);
                await controller.setHighContrast(false);
                await controller.setSimplifiedMode(false);
                await controller.setVoiceGuidedPrompts(false);
                await controller.setReducedMotion(false);
                await controller.setDataSaver(false);
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AccessibilityState accessibility) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Accessibility Preferences Header. '
          'Adjust text sizes, screen contrast, and navigation to best fit your comfort.',
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
          Semantics(
            label: 'Text scale slider: $scalePercent%',
            slider: true,
            child: Slider(
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
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Semantics(
                  label: 'Set text to standard size (100%)',
                  button: true,
                  child: OutlinedButton(
                    onPressed: () async {
                      await controller.setTextScale(1.0);
                      await _writeThrough(ref, ref.read(accessibilityControllerProvider));
                    },
                    child: const Text('Standard'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  label: 'Set text to large size (130%)',
                  button: true,
                  child: OutlinedButton(
                    onPressed: () async {
                      await controller.setTextScale(1.3);
                      await _writeThrough(ref, ref.read(accessibilityControllerProvider));
                    },
                    child: const Text('Large'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  label: 'Set text to extra large size (150%)',
                  button: true,
                  child: OutlinedButton(
                    onPressed: () async {
                      await controller.setTextScale(1.5);
                      await _writeThrough(ref, ref.read(accessibilityControllerProvider));
                    },
                    child: const Text('Extra Large'),
                  ),
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
          Semantics(
            label: 'High Contrast Mode toggle, currently ${state.highContrast ? "on" : "off"}',
            child: SwitchListTile(
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
          ),
          const Divider(),
          Semantics(
            label: 'Simplified Interface toggle, currently ${state.simplifiedMode ? "on" : "off"}',
            child: SwitchListTile(
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
          ),
          const Divider(),
          Semantics(
            label: 'Reduced Motion toggle, currently ${state.reducedMotion ? "on" : "off"}. '
                'When on, disables decorative animations regardless of the phone setting.',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reduced Motion'),
              subtitle: const Text(
                'Disables decorative animations throughout the app.',
              ),
              value: state.reducedMotion,
              onChanged: (enabled) async {
                await controller.setReducedMotion(enabled);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceGuidanceCard(
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
            'Assistance & Audio',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Voice-Guided Prompts toggle, currently ${state.voiceGuidedPrompts ? "on" : "off"}. '
                'When on, the app reads key actions aloud.',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Voice-Guided Prompts'),
              subtitle: const Text(
                'Reads out guidance hints for screen actions and forms.',
              ),
              value: state.voiceGuidedPrompts,
              onChanged: (enabled) async {
                await controller.setVoiceGuidedPrompts(enabled);
                if (enabled) {
                  // Announce immediately so the user hears confirmation.
                  await ref.read(ttsServiceProvider).speak(
                    'Voice-guided prompts are now on.',
                    voiceGuidedEnabled: true,
                  );
                }
              },
            ),
          ),
          const Divider(),
          Semantics(
            label: 'Data Saver toggle, currently ${state.dataSaver ? "on" : "off"}. '
                'When on, profile photos are compressed and hidden in lists.',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data Saver'),
              subtitle: const Text(
                'Shrinks photo uploads and hides images in lists to reduce data use.',
              ),
              value: state.dataSaver,
              onChanged: (enabled) async {
                await controller.setDataSaver(enabled);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    WidgetRef ref,
    AccessibilityState state,
    AccessibilityController controller,
  ) {
    final theme = Theme.of(context);

    final languages = [
      (code: 'en', label: 'English'),
      (code: 'si', label: 'සිංහල (Sinhala)'),
      (code: 'ta', label: 'தமிழ் (Tamil)'),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Language',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the language for the app interface.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final lang in languages)
            Semantics(
              label: '${lang.label} language option, '
                  '${state.locale == lang.code ? "currently selected" : ""}',
              selected: state.locale == lang.code,
              button: true,
              child: RadioListTile<String>(
                title: Text(lang.label),
                value: lang.code,
                groupValue: state.locale,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) async {
                  if (value == null) return;
                  await controller.setLocale(value);
                  // Update TTS language to match.
                  await ref.read(ttsServiceProvider).setLocale(value);
                },
              ),
            ),
        ],
      ),
    );
  }
}
