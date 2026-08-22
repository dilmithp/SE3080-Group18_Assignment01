import 'package:flutter/material.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';

/// An icon (or small indicator) seated in a soft tinted disc.
///
/// Empty, error and loading states all lead with one of these instead of a
/// bare icon floating on white — it gives those states a deliberate focal
/// point, and the disc's tint is what carries the status meaning (calm teal,
/// green, terracotta, red) alongside the glyph rather than colour alone.
class AppStatusIcon extends StatelessWidget {
  const AppStatusIcon({
    this.icon,
    this.child,
    this.background,
    this.foreground,
    this.size = 96,
    super.key,
  }) : assert(
          icon != null || child != null,
          'AppStatusIcon needs either an icon or a child.',
        );

  final IconData? icon;

  /// Rendered in place of [icon] — used by the loading state to seat a
  /// progress indicator in the same disc.
  final Widget? child;

  /// Defaults to `colorScheme.primaryContainer`.
  final Color? background;

  /// Defaults to `colorScheme.onPrimaryContainer`.
  final Color? foreground;

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? scheme.primaryContainer,
        shape: BoxShape.circle,
        // Visible as a hairline normally and as a solid ring in high
        // contrast, where the disc tint alone would be too subtle.
        border: Border.all(color: scheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: child ??
          Icon(
            icon,
            size: size * 0.42,
            color: foreground ?? scheme.onPrimaryContainer,
          ),
    );
  }
}

/// Centres a column of status content (icon, copy, action) with a sane
/// maximum width and lets it scroll rather than overflow — at the 1.6x text
/// scale the accessibility controller permits, a fixed column will not fit.
class StatusLayout extends StatelessWidget {
  const StatusLayout({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxProseWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}
