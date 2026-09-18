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
import 'package:elderly_companion/l10n/app_localizations.dart';

/// Screen allowing elderly users and volunteers to customize accessibility preferences:
/// - Dynamic Text Scaling (0.85x to 1.6x slider & quick presets)
/// - High Contrast Mode toggle
/// - Simplified Interface Mode toggle
/// - Reduced Motion toggle (independent of the OS "reduce motion" setting)
/// - Voice-Guided Prompts toggle (wired to [TtsService])
/// - Data Saver toggle
/// - Language picker (English / Sinhala / Tamil)
///
/// Every change also writes through to the signed-in user's persisted
/// `UserProfile.accessibilityPrefs` (best-effort, silently skipped if not
/// signed in or no profile exists yet) so it follows them to a new device —
/// see AccessibilityProfileSync for the seed-on-sign-in half of that sync.
/// `voiceGuidedPrompts`, `reducedMotion`, `dataSaver` and `languageCode` have
/// no persisted counterpart there and stay local-only.
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
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.accessibilitySettingsTitle),
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
          AppButton(
            label: loc.accessibilityReset,
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
                  SnackBar(content: Text(loc.accessibilityResetConfirm)),
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
    final loc = AppLocalizations.of(context)!;
    return Semantics(
      label: 'Accessibility Preferences Header',
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
                    loc.accessibilityCustomise,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.accessibilityCustomiseSubtitle,
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
    final loc = AppLocalizations.of(context)!;
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
                  loc.accessibilityTextSize(scalePercent),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.accessibilityTextPreview,
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
              loc.accessibilityPreviewSentence,
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
                  child: Text(loc.accessibilityStandard),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await controller.setTextScale(1.3);
                    await _writeThrough(ref, ref.read(accessibilityControllerProvider));
                  },
                  child: Text(loc.accessibilityLarge),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await controller.setTextScale(1.5);
                    await _writeThrough(ref, ref.read(accessibilityControllerProvider));
                  },
                  child: Text(loc.accessibilityExtraLarge),
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
    final loc = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.accessibilityDisplayLayout,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.accessibilityHighContrast),
            subtitle: Text(loc.accessibilityHighContrastDesc),
            value: state.highContrast,
            onChanged: (enabled) async {
              await controller.setHighContrast(enabled);
              await _writeThrough(ref, ref.read(accessibilityControllerProvider));
            },
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.accessibilitySimplified),
            subtitle: Text(loc.accessibilitySimplifiedDesc),
            value: state.simplifiedMode,
            onChanged: (enabled) async {
              await controller.setSimplifiedMode(enabled);
              await _writeThrough(ref, ref.read(accessibilityControllerProvider));
            },
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.accessibilityReducedMotion),
            subtitle: Text(loc.accessibilityReducedMotionDesc),
            value: state.reducedMotion,
            // Not written through to the profile — reducedMotion has no
            // persisted counterpart there, same as voiceGuidedPrompts.
            onChanged: (enabled) => controller.setReducedMotion(enabled),
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
    final loc = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.accessibilityAssistanceAudio,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.accessibilityVoiceGuided),
            subtitle: Text(loc.accessibilityVoiceGuidedDesc),
            value: state.voiceGuidedPrompts,
            onChanged: (enabled) async {
              await controller.setVoiceGuidedPrompts(enabled);
              if (enabled) {
                // Announce immediately so the user hears confirmation.
                await ref.read(ttsServiceProvider).speak(
                  loc.accessibilityVoiceGuided,
                  voiceGuidedEnabled: true,
                );
              }
            },
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.accessibilityDataSaver),
            subtitle: Text(loc.accessibilityDataSaverDesc),
            value: state.dataSaver,
            // Not written through to the profile — same as reducedMotion.
            onChanged: (enabled) => controller.setDataSaver(enabled),
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
    final loc = AppLocalizations.of(context)!;

    String labelFor(String? code) => switch (code) {
          'si' => loc.langSinhala,
          'ta' => loc.langTamil,
          _ => loc.langEnglish,
        };
    final currentCode = state.languageCode ?? 'en';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.accessibilityLanguage,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(loc.accessibilityLanguageDesc, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: Text(labelFor(state.languageCode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final selected = await showDialog<String?>(
                context: context,
                builder: (dialogContext) => SimpleDialog(
                  title: Text(loc.langPickerTitle),
                  children: [
                    for (final code in const ['en', 'si', 'ta'])
                      SimpleDialogOption(
                        onPressed: () => Navigator.of(dialogContext).pop(code),
                        child: Row(
                          children: [
                            if (code == currentCode)
                              Icon(Icons.check, color: theme.colorScheme.primary)
                            else
                              const SizedBox(width: 24),
                            const SizedBox(width: 8),
                            Text(labelFor(code)),
                          ],
                        ),
                      ),
                  ],
                ),
              );
              if (selected != null && selected != state.languageCode) {
                await controller.setLanguage(selected);
                await ref.read(ttsServiceProvider).setLocale(selected);
              }
            },
          ),
        ],
      ),
    );
  }
}
