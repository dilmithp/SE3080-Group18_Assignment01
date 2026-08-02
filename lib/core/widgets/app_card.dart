import 'package:flutter/material.dart';

import 'package:elderly_companion/core/theme/app_theme.dart';

/// Standard content container. Wraps [Card] with the app's default padding
/// and an optional tap handler sized to [AppTheme.minTapTarget].
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTheme.minTapTarget),
          child: card,
        ),
      ),
    );
  }
}
