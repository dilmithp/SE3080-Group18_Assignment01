import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';
import 'package:elderly_companion/features/sos/presentation/providers/sos_providers.dart';

/// Best-effort current position. Never throws, never blocks an alert on a
/// denied permission or a disabled location service — an SOS alert with no
/// location is still far better than no alert at all. Mirrors the
/// permission-request shape in `location_picker.dart`.
Future<Position?> _tryGetPosition() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getCurrentPosition()
        .timeout(const Duration(seconds: 6));
  } catch (_) {
    return null;
  }
}

/// Full-width, high-visibility emergency button. Drop it anywhere a signed-
/// in user needs one-tap access to help — Home screen and Profile screen
/// both use it.
///
/// Tapping it: (1) confirms (so an accidental tap can't fire a real alert),
/// (2) best-effort grabs a location fix, (3) writes a durable `SosAlert` via
/// [triggerSosAlertUseCaseProvider] so admins can see and act on it even if
/// nobody answers a phone, and (4) opens the device's own SMS composer
/// pre-filled to the user's emergency contact with a Google Maps link —
/// the same `url_launcher` approach [EmergencyContactCard]'s Call button
/// already uses, so it needs no backend and works with zero deployment.
class SosButton extends ConsumerStatefulWidget {
  const SosButton({super.key});

  @override
  ConsumerState<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends ConsumerState<SosButton> {
  bool _isSending = false;

  Future<void> _confirmAndSend(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.emergency, color: Colors.red, size: 36),
        title: const Text('Send an emergency alert?'),
        content: const Text(
          'This will text your emergency contact with your location (if '
          'available) and notify an admin. Only use this if you need help '
          'right now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yes, send SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _send(context);
  }

  Future<void> _send(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSending = true);
    try {
      final position = await _tryGetPosition();

      final result = await ref.read(triggerSosAlertUseCaseProvider)(
        userId: user.id,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      if (!context.mounted) return;

      result.fold(
        (failure) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message))),
        (_) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('SOS alert sent. Opening a text to your emergency contact...')),
          ),
      );

      final profile = await ref.read(profileProvider(user.id).future);
      final phone = profile?.emergencyContactPhone?.trim();
      if (phone == null || phone.isEmpty) {
        if (context.mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'No emergency contact is set on your profile — the alert was '
                'still recorded for an admin to see.',
              ),
            ),
          );
        }
        return;
      }

      final name = profile?.displayName ?? 'A CareConnect user';
      final locationLine = position != null
          ? 'Location: https://maps.google.com/?q=${position.latitude},${position.longitude}'
          : 'Location not available.';
      final message = '$name needs help now via CareConnect. $locationLine';

      final smsUri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: {'body': message},
      );
      await launchUrl(smsUri);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    if (userId == null) return const SizedBox.shrink();

    final activeAlert = ref.watch(mySosAlertProvider(userId)).valueOrNull;
    if (activeAlert != null) {
      return _ActiveAlertBanner(alertId: activeAlert.id);
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
        ),
        onPressed: _isSending ? null : () => _confirmAndSend(context),
        icon: _isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Icon(Icons.emergency),
        label: const Text(
          'Emergency SOS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

/// Shown instead of the SOS button itself while the user has an unresolved
/// alert — makes it impossible to stack a second alert on top of one still
/// active, and gives them a one-tap way to stand it down.
class _ActiveAlertBanner extends ConsumerWidget {
  const _ActiveAlertBanner({required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: Colors.red, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency, color: Colors.red),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Your SOS alert is active',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: userId == null
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await ref.read(resolveSosAlertUseCaseProvider)(
                        alertId: alertId,
                        resolvedBy: userId,
                      );
                      result.fold(
                        (failure) => messenger.showSnackBar(
                          SnackBar(content: Text(failure.message)),
                        ),
                        (_) => messenger.showSnackBar(
                          const SnackBar(content: Text("Marked as safe. Glad you're OK.")),
                        ),
                      );
                    },
              child: const Text("I'm safe now"),
            ),
          ),
        ],
      ),
    );
  }
}
