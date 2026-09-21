import 'package:flutter/material.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';

/// A compact error row for a slot inside a card or list, where the
/// full-screen [ErrorView] (96px icon, headline, retry button, prose-width
/// column) is too large and gets clipped or looks out of place. The message
/// text is wrapped in [Expanded] so it wraps instead of overflowing the row.
class InlineError extends StatelessWidget {
  const InlineError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
        ),
      ],
    );
  }
}
