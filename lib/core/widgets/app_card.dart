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
    final content = Padding(padding: padding, child: child);
    if (onTap == null) return Card(child: content);

    // The [InkWell] has to live *inside* the [Card]. Wrapping the card in one
    // instead paints the ripple behind the card's own opaque Material, which
    // swallows the press feedback entirely. `Clip.antiAlias` (from the card
    // theme) is what keeps the splash inside the rounded corners.
    return Card(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTheme.minTapTarget),
          child: content,
        ),
      ),
    );
  }
}
