import 'package:flutter/material.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';

/// Role selection as a list of always-visible options rather than a dropdown.
///
/// A dropdown hides every choice but one behind an extra tap and a menu that
/// can land off-screen — a poor trade for three fixed options, and a worse one
/// for a user with reduced dexterity. These read as radio buttons to a screen
/// reader and each is well over the 48dp tap minimum.
///
/// Shared by [SignupScreen] (picking a role at sign-up) and
/// `SelectRoleScreen` (correcting the placeholder role a brand-new
/// passwordless email-link sign-in is seeded with) — extracted here so both
/// stay visually identical rather than drifting apart as private copies.
class RolePicker extends StatelessWidget {
  const RolePicker({required this.value, required this.onChanged, super.key});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  /// Deliberately excludes [UserRole.admin] — nowhere in this app should a
  /// user be able to grant themselves the admin role. `firestore.rules`
  /// enforces this server-side too (a `users/{userId}` write can't set
  /// `role: 'admin'` except through an existing admin's own write); this
  /// list just keeps the option from ever being offered in the first place.
  static const _selectableRoles = [UserRole.elderly, UserRole.volunteer];

  static IconData _iconFor(UserRole role) => switch (role) {
        UserRole.elderly => Icons.elderly,
        UserRole.volunteer => Icons.volunteer_activism,
        UserRole.admin => Icons.admin_panel_settings_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('I am a...', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        for (final role in _selectableRoles) ...[
          _RoleOption(
            label: role.label,
            icon: _iconFor(role),
            selected: role == value,
            onTap: () => onChanged(role),
          ),
          if (role != _selectableRoles.last)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        borderRadius: AppRadius.controlAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.controlAll,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.controlAll,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outline,
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                // Selection is carried by a glyph as well as by colour and
                // weight, so it survives colour-blindness and high contrast.
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
