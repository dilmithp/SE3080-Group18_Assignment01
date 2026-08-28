import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';

/// Safety affordance for a signed-in user's own profile: shows whoever they
/// have listed as an emergency contact, with a large "Call" action that
/// dials the number directly.
///
/// Renders [SizedBox.shrink] when neither field is set, so a profile with no
/// emergency contact yet shows nothing rather than an empty/broken-looking
/// card.
///
/// Deliberately not built on [AppCard] — that widget has no way to override
/// its fill/border color, and this needs to read as visually distinct (a
/// safety affordance) without looking alarming. It borrows the same
/// hand-rolled tinted-`Container` technique `verification_screen.dart` uses
/// for its status panel, tinted with the `errorContainer`/`onErrorContainer`
/// pair — a calm, low-saturation tone in Material 3, not a raw red alert.
class EmergencyContactCard extends StatelessWidget {
  const EmergencyContactCard({required this.profile, super.key});

  final UserProfile profile;

  String? get _name {
    final value = profile.emergencyContactName?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  String? get _phone {
    final value = profile.emergencyContactPhone?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> _call(BuildContext context, String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final launched = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!launched && context.mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not start the call.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _name;
    final phone = _phone;
    if (name == null && phone == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: scheme.error, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency_outlined, color: scheme.onErrorContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Emergency contact',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (name != null)
            Text(
              name,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (phone != null) ...[
            SizedBox(height: name != null ? AppSpacing.xs : 0),
            Text(
              phone,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
          ],
          if (phone != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: name != null ? 'Call $name' : 'Call emergency contact',
              icon: Icons.call,
              onPressed: () => _call(context, phone),
            ),
          ],
        ],
      ),
    );
  }
}
