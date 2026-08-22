import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/profile_providers.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/presentation/providers/scheduling_providers.dart';

/// Owner: Ranketh (features/scheduling). Real session details wired to
/// [SessionRepository.getSession], with status-transition actions backed by
/// [UpdateSessionStatusUseCase].
class SessionDetailsScreen extends ConsumerWidget {
  const SessionDetailsScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider(sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Session details')),
      body: sessionAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (session) => _SessionBody(session: session),
      ),
    );
  }
}

class _SessionBody extends ConsumerStatefulWidget {
  const _SessionBody({required this.session});

  final Session session;

  @override
  ConsumerState<_SessionBody> createState() => _SessionBodyState();
}

class _SessionBodyState extends ConsumerState<_SessionBody> {
  bool _isUpdating = false;

  Future<void> _updateStatus(SessionStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isUpdating = true);
    try {
      final useCase = ref.read(updateSessionStatusUseCaseProvider);
      final result = await useCase(
        sessionId: widget.session.id,
        status: status,
      );
      result.fold(
        (failure) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message))),
        (_) {
          // sessionProvider is a one-shot FutureProvider (getSession), not a
          // stream — without this, the screen keeps showing the pre-update
          // status and stale action buttons until the user navigates away
          // and back.
          ref.invalidate(sessionProvider(widget.session.id));
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Session ${status.label.toLowerCase()}.')));
        },
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  /// The signed-in user's counterpart on this session — whichever of
  /// requester/volunteer isn't them. `null` while auth state is still
  /// loading or the user isn't signed in; the notes card below just stays
  /// hidden in that case rather than guessing.
  String? _otherPartyId(Session session, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    if (userId == null) return null;
    return userId == session.requesterId ? session.volunteerId : session.requesterId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;
    final formatted =
        DateFormat('EEEE, d MMMM · h:mm a').format(session.scheduledAt);
    final otherPartyId = _otherPartyId(session, ref);
    final communicationNotes = otherPartyId == null
        ? null
        : ref.watch(profileProvider(otherPartyId)).valueOrNull?.accessibilityPrefs
            .communicationNotes;
    // Drops the duration figure (secondary detail — location and time are
    // what actually matter for showing up) and enlarges the header icon,
    // matching the same simplified treatment as matching's screens.
    final simplified = ref.watch(
      accessibilityControllerProvider.select((s) => s.simplifiedMode),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Row(
                  children: [
                    AppStatusIcon(
                      icon: Icons.event_note_outlined,
                      size: simplified ? 88 : 64,
                      background: theme.colorScheme.tertiaryContainer,
                      foreground: theme.colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatted, style: theme.textTheme.titleLarge),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            session.status.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(icon: Icons.place_outlined, label: session.location),
                    if (!simplified) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(
                        icon: Icons.timer_outlined,
                        label: '${session.durationMinutes} minutes',
                      ),
                    ],
                    if (session.notes != null && session.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.notes_outlined, label: session.notes!),
                    ],
                  ],
                ),
              ),
              if (communicationNotes != null && communicationNotes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.record_voice_over_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Communication notes', style: theme.textTheme.titleLarge),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(communicationNotes, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              ..._actionsFor(session.status),
              const SizedBox(height: AppSpacing.md),
              if (session.status == SessionStatus.completed)
                AppButton(
                  label: 'Leave feedback',
                  icon: Icons.chat_bubble_outline,
                  secondary: true,
                  onPressed: () =>
                      context.push(RouteNames.sessionFeedbackPath(session.id)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actionsFor(SessionStatus status) {
    switch (status) {
      case SessionStatus.requested:
        return [
          AppButton(
            label: 'Confirm session',
            icon: Icons.check_circle_outline,
            isLoading: _isUpdating,
            onPressed: () => _updateStatus(SessionStatus.confirmed),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Cancel',
            icon: Icons.close,
            secondary: true,
            isLoading: _isUpdating,
            onPressed: () => _updateStatus(SessionStatus.cancelled),
          ),
        ];
      case SessionStatus.confirmed:
        return [
          AppButton(
            label: 'Mark completed',
            icon: Icons.task_alt_outlined,
            isLoading: _isUpdating,
            onPressed: () => _updateStatus(SessionStatus.completed),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Cancel',
            icon: Icons.close,
            secondary: true,
            isLoading: _isUpdating,
            onPressed: () => _updateStatus(SessionStatus.cancelled),
          ),
        ];
      case SessionStatus.completed:
      case SessionStatus.cancelled:
        return const [];
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}
