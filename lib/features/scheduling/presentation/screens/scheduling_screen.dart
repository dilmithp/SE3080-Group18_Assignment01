import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/widgets/empty_view.dart';

/// Placeholder screen — owner: Ranketh (features/scheduling).
class SchedulingScreen extends ConsumerWidget {
  const SchedulingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions — Owner: Ranketh')),
      body: const EmptyView(
        icon: Icons.event_available_outlined,
        message: 'No sessions booked yet.',
      ),
    );
  }
}
