import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';
import 'package:elderly_companion/features/matching/presentation/providers/matching_providers.dart';

/// Placeholder screen — owner: Wijekoon (features/matching).
class MatchingScreen extends ConsumerWidget {
  const MatchingScreen({super.key});

  Future<void> _findMatches(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final useCase = ref.read(findMatchesUseCaseProvider);
      await useCase(
        const MatchCriteria(
          locality: 'placeholder-locality',
          radiusKm: 5,
          requiredSkills: [],
          preferredTimes: [],
        ),
      );
    } on UnimplementedError catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message ?? 'Not implemented yet.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matching')),
      body: EmptyView(
        icon: Icons.diversity_3_outlined,
        message: 'No matches found yet.\nOwner: Wijekoon — features/matching',
        action: AppButton(
          label: 'Find matches',
          onPressed: () => _findMatches(context, ref),
        ),
      ),
    );
  }
}
