import 'package:flutter/material.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';

/// Full-space error state with a retry action. Prefer
/// [ErrorView.fromFailure] when displaying a [Failure] from a repository
/// call so the message stays consistent across screens.
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    super.key,
  });

  factory ErrorView.fromFailure(Failure failure, {VoidCallback? onRetry}) {
    return ErrorView(message: failure.message, onRetry: onRetry);
  }

  final String message;

  /// Plain-language headline. The detail in [message] is often technical, so
  /// this carries the meaning for a reader who will not parse the rest.
  final String title;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StatusLayout(
      children: [
        AppStatusIcon(
          icon: Icons.error_outline,
          background: theme.colorScheme.errorContainer,
          foreground: theme.colorScheme.onErrorContainer,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Try again', icon: Icons.refresh, onPressed: onRetry),
        ],
      ],
    );
  }
}
