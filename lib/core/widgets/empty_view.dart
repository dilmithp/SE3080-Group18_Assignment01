import 'package:flutter/material.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';

/// Full-space empty state (no results, nothing booked yet, etc.).
class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.action,
    this.footnote,
    super.key,
  });

  final String message;
  final IconData icon;

  /// Optional short headline above [message]. Screens that can name the
  /// situation ("No sessions yet") should — a lone paragraph reads like an
  /// error even when nothing is wrong.
  final String? title;

  final Widget? action;

  /// Fine print below the action — secondary context that should be available
  /// but must not compete with the message for attention.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StatusLayout(
      children: [
        AppStatusIcon(icon: icon),
        const SizedBox(height: AppSpacing.lg),
        if (title != null) ...[
          Text(title!, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          message,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[
          const SizedBox(height: AppSpacing.xl),
          action!,
        ],
        if (footnote != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            footnote!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
