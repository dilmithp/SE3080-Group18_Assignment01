import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/theme/app_theme.dart';

/// Standard content container. Wraps [Card] with the app's default padding
/// and an optional tap handler sized to [AppTheme.minTapTarget].
///
/// Content padding isn't expressible via [ThemeData]'s `CardTheme` (it has
/// no such field), so — unlike [AppButton]/[AppTextField], which get their
/// simplified-mode sizing for free from the theme — this widget reads
/// [accessibilityControllerProvider] directly to bump its own default
/// padding when [AccessibilityState.simplifiedMode] is on. An explicit
/// [padding] always wins over both defaults.
class AppCard extends ConsumerWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simplified = ref.watch(
      accessibilityControllerProvider.select((s) => s.simplifiedMode),
    );
    final effectivePadding = padding ??
        EdgeInsets.all(simplified ? AppSpacing.lg : AppSpacing.md);
    final tapTarget = simplified ? AppTheme.minTapTargetSimplified : AppTheme.minTapTarget;
    final content = Padding(padding: effectivePadding, child: child);
    if (onTap == null) return Card(child: content);

    // The [InkWell] has to live *inside* the [Card]. Wrapping the card in one
    // instead paints the ripple behind the card's own opaque Material, which
    // swallows the press feedback entirely. `Clip.antiAlias` (from the card
    // theme) is what keeps the splash inside the rounded corners.
    return Card(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tapTarget),
          child: content,
        ),
      ),
    );
  }
}
