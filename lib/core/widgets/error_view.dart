import 'package:flutter/material.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';

/// Full-space error state with a retry action. Prefer
/// [ErrorView.fromFailure] when displaying a [Failure] from a repository
/// call so the message stays consistent across screens.
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.message,
    this.onRetry,
    super.key,
  });

  factory ErrorView.fromFailure(Failure failure, {VoidCallback? onRetry}) {
    return ErrorView(message: failure.message, onRetry: onRetry);
  }

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(label: 'Try again', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
