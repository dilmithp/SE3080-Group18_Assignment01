import 'package:flutter/material.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';

/// Primary call-to-action button. Wraps [ElevatedButton] so every button in
/// the app gets the same minimum tap target, shape, elevation and loading
/// affordance for free — screens should not reach for [ElevatedButton]
/// directly.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.secondary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// Renders as an [OutlinedButton] instead of a filled [ElevatedButton].
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = secondary ? scheme.primary : scheme.onPrimary;
    final button = secondary
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: _buttonStyle(scheme),
            child: _content(foreground),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: _buttonStyle(scheme),
            child: _content(foreground),
          );

    return Semantics(
      button: true,
      label: isLoading ? '$label, in progress' : label,
      enabled: !isLoading && onPressed != null,
      child: button,
    );
  }

  /// Explicit minimum tap target (48x48 dp) complying with WCAG 2.5.5 and
  /// [androidTapTargetGuideline]. A loading button is disabled so it cannot be
  /// pressed twice, but it preserves resting colors to avoid looking like an error.
  ButtonStyle _buttonStyle(ColorScheme scheme) {
    const minTarget = Size(64, kMinInteractiveDimension);
    if (secondary) {
      return OutlinedButton.styleFrom(
        minimumSize: minTarget,
        disabledForegroundColor: isLoading ? scheme.primary : null,
      );
    }
    return ElevatedButton.styleFrom(
      minimumSize: minTarget,
      disabledBackgroundColor: isLoading ? scheme.primary : null,
      disabledForegroundColor: isLoading ? scheme.onPrimary : null,
    );
  }

  Widget _content(Color foreground) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
