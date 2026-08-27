import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/app_user.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_feedback.dart';
import 'package:elderly_companion/features/scheduling/domain/services/feedback_eligibility.dart';
import 'package:elderly_companion/features/scheduling/presentation/providers/scheduling_providers.dart';

/// Owner: Ranketh (features/scheduling). Lets the signed-in user rate and
/// comment on a completed session.
///
/// The route is reachable directly, so eligibility is checked here as well
/// as on the details screen that links to it — same [FeedbackEligibility]
/// rule, so the two cannot disagree.
class SessionFeedbackScreen extends ConsumerStatefulWidget {
  const SessionFeedbackScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<SessionFeedbackScreen> createState() =>
      _SessionFeedbackScreenState();
}

class _SessionFeedbackScreenState extends ConsumerState<SessionFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Still the single source of truth for the rating so [_submit] is
  /// unchanged — the stars below just write into it. Typing a number into a
  /// text box is a poor ask of someone with reduced dexterity when five large
  /// targets say the same thing.
  final _ratingController = TextEditingController(text: '5');
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  int get _rating => int.tryParse(_ratingController.text) ?? 5;

  @override
  void dispose() {
    _ratingController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit(String raterId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      final useCase = ref.read(submitFeedbackUseCaseProvider);
      final result = await useCase(
        sessionId: widget.sessionId,
        raterId: raterId,
        rating: int.parse(_ratingController.text),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      result.fold(
        (failure) => _showMessage(failure.message),
        (_) {
          // Feedback cannot be edited once written (firestore.rules denies
          // updates), so there is nothing left to do on this screen —
          // re-read the list behind us and hand the user back to the
          // session they just rated.
          ref.invalidate(sessionFeedbackProvider(widget.sessionId));
          _showMessage('Thank you — your feedback has been recorded.');
          if (mounted && context.canPop()) context.pop();
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final sessionAsync = ref.watch(sessionProvider(widget.sessionId));
    final feedbackAsync = ref.watch(sessionFeedbackProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Leave feedback')),
      body: _body(authState, sessionAsync, feedbackAsync),
    );
  }

  Widget _body(
    AsyncValue<AppUser?> authState,
    AsyncValue<Session> sessionAsync,
    AsyncValue<List<SessionFeedback>> feedbackAsync,
  ) {
    if (authState.isLoading || sessionAsync.isLoading || feedbackAsync.isLoading) {
      return const LoadingView();
    }

    final error = authState.error ?? sessionAsync.error ?? feedbackAsync.error;
    if (error != null) return ErrorView(message: error.toString());

    final user = authState.valueOrNull;
    if (user == null) {
      return const EmptyView(
        icon: Icons.lock_outline,
        title: 'Sign in first',
        message: 'You need to be signed in before you can leave feedback.',
      );
    }

    final session = sessionAsync.requireValue;
    final feedback = feedbackAsync.requireValue;
    const eligibility = FeedbackEligibility();

    if (!eligibility.canLeaveFeedback(
      session: session,
      userId: user.id,
      existingFeedback: feedback,
    )) {
      return _ineligibleView(
        session: session,
        userId: user.id,
        feedback: feedback,
        eligibility: eligibility,
      );
    }

    return _FeedbackForm(
      formKey: _formKey,
      rating: _rating,
      onRatingChanged: (rating) => setState(
        () => _ratingController.text = '$rating',
      ),
      commentController: _commentController,
      isSubmitting: _isSubmitting,
      onSubmit: () => _submit(user.id),
    );
  }

  /// Says *which* reason the form is unavailable rather than a single
  /// catch-all message — "you already rated this" and "this session has not
  /// happened yet" call for very different next steps.
  Widget _ineligibleView({
    required Session session,
    required String userId,
    required List<SessionFeedback> feedback,
    required FeedbackEligibility eligibility,
  }) {
    if (!eligibility.isParticipant(session: session, userId: userId)) {
      return const EmptyView(
        icon: Icons.person_off_outlined,
        title: 'Not your session',
        message: 'Only the two people who arranged a session can leave '
            'feedback on it.',
      );
    }
    if (eligibility.hasRated(userId: userId, existingFeedback: feedback)) {
      return const EmptyView(
        icon: Icons.check_circle_outline,
        title: 'Feedback already sent',
        message: 'You have already rated this session. Feedback cannot be '
            'changed once it is sent.',
      );
    }
    return const EmptyView(
      icon: Icons.schedule_outlined,
      title: 'Not finished yet',
      message: 'You can leave feedback once the session has been marked '
          'completed.',
    );
  }
}

class _FeedbackForm extends StatelessWidget {
  const _FeedbackForm({
    required this.formKey,
    required this.rating,
    required this.onRatingChanged,
    required this.commentController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final TextEditingController commentController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'How did it go?',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your feedback helps us make better matches next time.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: _RatingPicker(
                      value: rating,
                      onChanged: onRatingChanged,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Comment (optional)',
                    hint: 'Anything you would like us to know?',
                    controller: commentController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Submit feedback',
                    isLoading: isSubmitting,
                    onPressed: onSubmit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Module owner: Ranketh — features/scheduling',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
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

/// Five large star targets plus the rating spelled out in words, so the value
/// never depends on counting filled shapes.
class _RatingPicker extends StatelessWidget {
  const _RatingPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const List<String> _words = [
    'Poor',
    'Fair',
    'Good',
    'Very good',
    'Excellent',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text('Your rating', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (var star = 1; star <= _words.length; star++)
              IconButton(
                icon: Icon(
                  star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
                iconSize: 36,
                color: theme.colorScheme.tertiary,
                tooltip: '$star ${star == 1 ? 'star' : 'stars'}',
                isSelected: star <= value,
                onPressed: () => onChanged(star),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_words[value - 1]} — $value out of ${_words.length}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
