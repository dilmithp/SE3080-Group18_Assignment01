import 'package:flutter/material.dart';

/// Primary call-to-action button. Wraps [ElevatedButton] so every button in
/// the app gets the same minimum tap target and loading affordance for
/// free — screens should not reach for [ElevatedButton] directly.
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
    final child = isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              );

    final effectiveOnPressed = isLoading ? null : onPressed;

    if (secondary) {
      return OutlinedButton(
        onPressed: effectiveOnPressed,
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: effectiveOnPressed,
      child: child,
    );
  }
}
