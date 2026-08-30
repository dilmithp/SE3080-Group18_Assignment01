import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/utils/validators.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/skeleton_loader.dart';
import 'package:elderly_companion/core/widgets/staggered_entrance.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_criteria.dart';
import 'package:elderly_companion/features/matching/domain/strategies/matching_strategy.dart';
import 'package:elderly_companion/features/matching/presentation/providers/matching_providers.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';

/// Owner: Wijekoon (features/matching). Real search form wired to
/// [FindMatchesUseCase]; results render as ranked, tappable cards.
class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({super.key});

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localityController = TextEditingController();
  final _skillsController = TextEditingController();
  final Set<String> _preferredDays = {};
  MatchingStrategyType _strategyType = MatchingStrategyType.balanced;

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

      // Resolve the searcher's own coordinates so results can be ranked
      // and filtered by real distance rather than locality name alone.
      // Best-effort: a searcher with no saved profile yet simply falls
      // back to locality-only matching (origin stays null). Awaiting
      // `.future` (rather than reading the provider's cached AsyncValue)
      // avoids a race against the stream's first emission on a screen
      // that never otherwise watches this provider.
      final viewer = ref.read(authStateProvider).valueOrNull;
      if (viewer == null) {
        setState(() {
          _isSearching = false;
          _failure = const AuthFailure('Sign in to search for matches.');
        });
        return;
      }
      final origin = (await ref.read(profileProvider(viewer.id).future))?.geoPoint;

      final result = await useCase(
        MatchCriteria(
          locality: _localityController.text.trim(),
          radiusKm: 5,
          requiredSkills: skills,
          preferredTimes: _preferredDays.toList(),
          viewerId: viewer.id,
          viewerRole: viewer.role,
          origin: origin,
          strategyType: _strategyType,
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
    // Simplified mode drops the optional refinement fields (skills,
    // preferred days) so the form is just "where" + one big button —
    // fewer decisions before the primary action, per AccessibilityState's
    // documented intent.
    final simplified = ref.watch(
      accessibilityControllerProvider.select((s) => s.simplifiedMode),
    );

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
                        if (!simplified) ...[
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Skills (optional)',
                            hint: 'e.g. gardening, cooking',
                            helperText: 'Separate with commas',
                            controller: _skillsController,
                            prefixIcon: Icons.star_outline,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Rank matches by',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final type in MatchingStrategyType.values)
                                ChoiceChip(
                                  label: Text(type.label),
                                  selected: _strategyType == type,
                                  onSelected: (_) =>
                                      setState(() => _strategyType = type),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Preferred days (optional)',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final day in _weekdays)
                                FilterChip(
                                  label: Text(day),
                                  selected: _preferredDays.contains(day),
                                  onSelected: (selected) => setState(() {
                                    if (selected) {
                                      _preferredDays.add(day);
                                    } else {
                                      _preferredDays.remove(day);
                                    }
                                  }),
                                ),
                            ],
                          ),
                        ],
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
                    isLoading: _isSearching,
                    hasSearched: _hasSearched,
                    failure: _failure,
                    results: _results,
                    simplified: simplified,
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
    required this.isLoading,
    required this.hasSearched,
    required this.failure,
    required this.results,
    required this.simplified,
    required this.onRetry,
    required this.onTap,
  });

  final bool isLoading;
  final bool hasSearched;
  final Failure? failure;
  final List<MatchCandidate> results;
  final bool simplified;
  final VoidCallback onRetry;
  final ValueChanged<MatchCandidate> onTap;

  @override
  Widget build(BuildContext context) {
    // Checked first so a re-search (retry, or edited filters) shows a clear
    // loading panel here rather than leaving stale results/errors on screen
    // with only the small button spinner as a hint that anything changed.
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: SizedBox(height: 4 * 88, child: SkeletonList(count: 3)),
      );
    }

    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: ErrorView.fromFailure(failure!, onRetry: onRetry),
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
        for (final entry in results.asMap().entries) ...[
          StaggeredEntrance(
            index: entry.key,
            child: _CandidateCard(
              candidate: entry.value,
              simplified: simplified,
              onTap: () => onTap(entry.value),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.simplified,
    required this.onTap,
  });

  final MatchCandidate candidate;
  final bool simplified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchPercent = (candidate.matchScore.clamp(0.0, 1.0) * 100).round();
    final name = candidate.profile.displayName.isEmpty
        ? 'Companion'
        : candidate.profile.displayName;

    // Simplified mode keeps only the two things an elderly user needs to
    // decide whether to open this candidate — who, and the single biggest
    // reason they matched — and drops the secondary skills/locality line
    // and the numeric match-percent badge.
    if (simplified) {
      return AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Hero(
              tag: 'match-avatar-${candidate.userId}',
              child: AppStatusIcon(
                icon: Icons.person,
                size: 72,
                background: theme.colorScheme.primaryContainer,
                foreground: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.headlineSmall),
                  if (candidate.matchReasons.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      candidate.matchReasons.first,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Hero(
            tag: 'match-avatar-${candidate.userId}',
            child: AppStatusIcon(
              icon: Icons.person,
              size: 56,
              background: theme.colorScheme.primaryContainer,
              foreground: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleLarge),
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
                if (candidate.matchReasons.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    candidate.matchReasons.first,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
