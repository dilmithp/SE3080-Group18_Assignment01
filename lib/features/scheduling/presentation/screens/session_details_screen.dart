import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';

/// Placeholder screen — owner: Ranketh (features/scheduling).
class SessionDetailsScreen extends ConsumerWidget {
  const SessionDetailsScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Session $sessionId\nOwner: Ranketh — features/scheduling',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Leave feedback',
                onPressed: () =>
                    context.push(RouteNames.sessionFeedbackPath(sessionId)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
