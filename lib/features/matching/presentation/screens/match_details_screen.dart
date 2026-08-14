import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/utils/validators.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/scheduling/presentation/providers/scheduling_providers.dart';

/// Owner: Wijekoon (features/matching). [candidate] arrives via the
/// go_router `extra` payload set by [MatchingScreen] — matching has no
/// "fetch one candidate by id" method, so a direct deep link without that
/// payload shows a fallback rather than a real profile.
class MatchDetailsScreen extends ConsumerWidget {
  const MatchDetailsScreen({required this.candidateId, this.candidate, super.key});

  final String candidateId;
  final MatchCandidate? candidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final candidate = this.candidate;
    // Simplified mode drops the dense stat-tile row and the skills-chip
    // list — secondary detail — and keeps the name, the plain-language
    // "why this match" reasons, and the primary booking action.
    final simplified = ref.watch(
      accessibilityControllerProvider.select((s) => s.simplifiedMode),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Match details')),
      body: candidate == null
          ? const EmptyView(
              icon: Icons.person_search_outlined,
              title: 'Open this from your matches',
              message: 'Candidate details are only available right after a '
                  'search — go back and tap a match from the results list.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        child: Row(
                          children: [
                            AppStatusIcon(
                              icon: Icons.person,
                              size: 72,
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
                                    style: theme.textTheme.headlineMedium,
                                  ),
                                  if (candidate.profile.locality.isNotEmpty)
                                    Text(
                                      candidate.profile.locality,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!simplified) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                label: 'Trust score',
                                value:
                                    '${(candidate.trustScore.clamp(0.0, 1.0) * 100).round()}%',
                                icon: Icons.verified_user_outlined,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _StatTile(
                                label: 'Match score',
                                value:
                                    '${(candidate.matchScore.clamp(0.0, 1.0) * 100).round()}%',
                                icon: Icons.diversity_3_outlined,
                              ),
                            ),
                            if (candidate.distanceKm > 0) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _StatTile(
                                  label: 'Distance',
                                  value: '${candidate.distanceKm.toStringAsFixed(1)} km',
                                  icon: Icons.near_me_outlined,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (candidate.matchReasons.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Why this match', style: theme.textTheme.titleLarge),
                              const SizedBox(height: AppSpacing.sm),
                              for (final reason in candidate.matchReasons)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(reason, style: theme.textTheme.bodyLarge),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (candidate.profile.bio.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('About', style: theme.textTheme.titleLarge),
                              const SizedBox(height: AppSpacing.sm),
                              Text(candidate.profile.bio, style: theme.textTheme.bodyLarge),
                            ],
                          ),
                        ),
                      ],
                      if (!simplified && candidate.profile.skillsOffered.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Skills offered', style: theme.textTheme.titleLarge),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  for (final skill in candidate.profile.skillsOffered)
                                    Chip(
                                      label: Text(skill),
                                      backgroundColor: theme.colorScheme.secondaryContainer,
                                      labelStyle: TextStyle(
                                        color: theme.colorScheme.onSecondaryContainer,
                                      ),
                                      side: BorderSide.none,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: 'Book a session',
                        icon: Icons.event_available_outlined,
                        onPressed: () => _openBookingSheet(context, ref, candidate),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _openBookingSheet(
    BuildContext context,
    WidgetRef ref,
    MatchCandidate candidate,
  ) async {
    final authState = ref.read(authStateProvider);
    final requesterId = authState.valueOrNull?.id;
    if (requesterId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Sign in first.')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _BookingSheet(
        requesterId: requesterId,
        volunteerId: candidate.userId,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: theme.textTheme.titleLarge),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal booking form: date, time, duration and a free-text location.
class _BookingSheet extends ConsumerStatefulWidget {
  const _BookingSheet({required this.requesterId, required this.volunteerId});

  final String requesterId;
  final String volunteerId;

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);
    try {
      final scheduledAt =
          DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
      final useCase = ref.read(bookSessionUseCaseProvider);
      final result = await useCase(
        requesterId: widget.requesterId,
        volunteerId: widget.volunteerId,
        scheduledAt: scheduledAt,
        durationMinutes: int.tryParse(_durationController.text) ?? 60,
        location: _locationController.text.trim(),
      );
      result.fold(
        (failure) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message))),
        (session) {
          navigator.pop();
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Session booked.')));
          navigator.context.push(RouteNames.sessionDetailsPath(session.id));
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Book a session', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Duration (minutes)',
              controller: _durationController,
              keyboardType: TextInputType.number,
              validator: (value) {
                final minutes = int.tryParse(value ?? '');
                if (minutes == null || minutes <= 0) {
                  return 'Enter a duration in minutes.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Location',
              hint: 'Where will you meet?',
              controller: _locationController,
              prefixIcon: Icons.place_outlined,
              validator: (value) => Validators.required(value, fieldName: 'Location'),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Confirm booking',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
