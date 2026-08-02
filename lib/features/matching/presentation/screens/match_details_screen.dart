import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder screen — owner: Wijekoon (features/matching).
class MatchDetailsScreen extends ConsumerWidget {
  const MatchDetailsScreen({required this.candidateId, super.key});

  final String candidateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Candidate: $candidateId'),
              const SizedBox(height: 8),
              const Text('Owner: Wijekoon — features/matching'),
            ],
          ),
        ),
      ),
    );
  }
}
