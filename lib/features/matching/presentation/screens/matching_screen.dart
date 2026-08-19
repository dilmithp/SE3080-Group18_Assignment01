import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/utils/validators.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';
import 'package:elderly_companion/features/matching/presentation/providers/matching_providers.dart';

/// Owner: Wijekoon (features/matching). Real search form wired to
/// [FindMatchesUseCase]; results render as ranked, tappable cards.
class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({super.key});

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localityController = TextEditingController();
  final _skillsController = TextEditingController();

  bool _isSearching = false;
  bool _hasSearched = false;
  Failure? _failure;
  List<MatchCandidate> _results = const [];

  @override
  void dispose() {
    _localityController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSearching = true;
      _failure = null;
    });
    try {
      final useCase = ref.read(findMatchesUseCaseProvider);
      final skills = _skillsController.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList();
      final result = await useCase(
        MatchCriteria(
          locality: _localityController.text.trim(),
          radiusKm: 5,
          requiredSkills: skills,
          preferredTimes: const [],
        ),
      );
      result.fold(
        (failure) => setState(() => _failure = failure),
        (candidates) => setState(() => _results = candidates),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
        });
      }
    }
  }

  void _openCandidate(MatchCandidate candidate) {
    context.push(
      RouteNames.matchDetailsPath(candidate.userId),
      extra: candidate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a match')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Locality',
                          hint: 'Your neighbourhood',
                          controller: _localityController,
                          prefixIcon: Icons.place_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.required(value, fieldName: 'Locality'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Skills (optional)',
                          hint: 'e.g. gardening, cooking',
                          helperText: 'Separate with commas',
                          controller: _skillsController,
                          prefixIcon: Icons.star_outline,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: 'Find matches',
                          icon: Icons.search_rounded,
                          isLoading: _isSearching,
                          onPressed: _search,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Results(
                    hasSearched: _hasSearched,
                    failure: _failure,
                    results: _results,
                    onRetry: _search,
                    onTap: _openCandidate,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.hasSearched,
    required this.failure,
    required this.results,
    required this.onRetry,
    required this.onTap,
  });

  final bool hasSearched;
  final Failure? failure;
  final List<MatchCandidate> results;
  final VoidCallback onRetry;
  final ValueChanged<MatchCandidate> onTap;

  @override
  Widget build(BuildContext context) {
    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Text(
              failure!.message,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'Try again', icon: Icons.refresh, onPressed: onRetry),
          ],
        ),
      );
    }

    if (!hasSearched) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: EmptyView(
          icon: Icons.diversity_3_outlined,
          title: 'No matches yet',
          message: 'Search to find companions and helpers near you who '
              'share your interests and free time.',
        ),
      );
    }

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: EmptyView(
          icon: Icons.search_off,
          title: 'No matches found',
          message: 'Try a different locality or fewer required skills.',
        ),
      );
    }

    return Column(
      children: [
        for (final candidate in results) ...[
          _CandidateCard(candidate: candidate, onTap: () => onTap(candidate)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate, required this.onTap});

  final MatchCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchPercent = (candidate.matchScore.clamp(0.0, 1.0) * 100).round();

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AppStatusIcon(
            icon: Icons.person,
            size: 56,
            background: theme.colorScheme.primaryContainer,
            foreground: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.profile.displayName.isEmpty
                      ? 'Companion'
                      : candidate.profile.displayName,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  candidate.profile.skillsOffered.isEmpty
                      ? candidate.profile.locality
                      : candidate.profile.skillsOffered.join(', '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: AppRadius.pillAll,
            ),
            child: Text(
              '$matchPercent%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
