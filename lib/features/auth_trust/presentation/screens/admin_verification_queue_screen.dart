import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/verification_request.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/notifications/domain/entities/notification_type.dart';
import 'package:elderly_companion/features/notifications/presentation/providers/notifications_providers.dart';

/// Owner: Pathirana (features/auth_trust). Admin-only reviewer queue: lists
/// every [VerificationRequest] still `pending` (via
/// [pendingVerificationRequestsProvider]) and lets an admin approve or
/// reject each one, driving
/// [reviewVerificationRequestUseCaseProvider]. This is the reviewer-facing
/// counterpart to [VerificationScreen] (the submitter-facing half).
///
/// This is a defense-in-depth UX guard only — the actual `update` on
/// `verification_requests` is already restricted to admins server-side by
/// `firestore.rules` (`allow update: if isAdmin();`), so a non-admin who
/// somehow reached this screen still could not perform the write.
class AdminVerificationQueueScreen extends ConsumerStatefulWidget {
  const AdminVerificationQueueScreen({super.key});

  @override
  ConsumerState<AdminVerificationQueueScreen> createState() =>
      _AdminVerificationQueueScreenState();
}

class _AdminVerificationQueueScreenState
    extends ConsumerState<AdminVerificationQueueScreen> {
  /// Request ids with a review in flight, so each card can show its own
  /// spinner instead of blocking the whole queue.
  final Set<String> _reviewingIds = {};

  Future<void> _review(
    VerificationRequest request, {
    required String reviewerId,
    required bool approve,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _reviewingIds.add(request.id));
    try {
      final useCase = ref.read(reviewVerificationRequestUseCaseProvider);
      final result = await useCase(
        requestId: request.id,
        reviewerId: reviewerId,
        approve: approve,
      );
      result.fold(
        (failure) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message))),
        (_) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(approve ? 'Request approved.' : 'Request rejected.'),
              ),
            );
          // Best-effort — a failed notification must never undo or mask the
          // review decision that already succeeded above.
          unawaited(
            ref.read(createNotificationUseCaseProvider)(
              userId: request.userId,
              type: approve
                  ? NotificationType.verificationApproved
                  : NotificationType.verificationRejected,
              title: approve ? "You're verified" : 'Verification not approved',
              body: approve
                  ? 'Your identity document was approved. Your verified badge '
                      'is now visible to matches.'
                  : 'Your last submission was not approved. You can submit a '
                      'new document from the Verification screen.',
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _reviewingIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification queue')),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (user) {
          if (user == null || user.role != UserRole.admin) {
            return const EmptyView(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admins only',
              message: 'You need an admin account to review verification '
                  'requests.',
            );
          }
          return _QueueBody(
            reviewingIds: _reviewingIds,
            onApprove: (request) => _review(
              request,
              reviewerId: user.id,
              approve: true,
            ),
            onReject: (request) => _review(
              request,
              reviewerId: user.id,
              approve: false,
            ),
          );
        },
      ),
    );
  }
}

class _QueueBody extends ConsumerWidget {
  const _QueueBody({
    required this.reviewingIds,
    required this.onApprove,
    required this.onReject,
  });

  final Set<String> reviewingIds;
  final ValueChanged<VerificationRequest> onApprove;
  final ValueChanged<VerificationRequest> onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingVerificationRequestsProvider);

    return requestsAsync.when(
      loading: () => const LoadingView(message: 'Loading pending requests...'),
      error: (error, _) => ErrorView(message: error.toString()),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyView(
            icon: Icons.fact_check_outlined,
            title: 'All caught up',
            message: 'No pending requests. New submissions will appear '
                'here automatically.',
          );
        }
        return ListView.separated(
          padding: AppSpacing.screen,
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final request = requests[index];
            return _RequestCard(
              request: request,
              isReviewing: reviewingIds.contains(request.id),
              onApprove: () => onApprove(request),
              onReject: () => onReject(request),
            );
          },
        );
      },
    );
  }
}

/// One pending request rendered dense enough for an admin to triage a long
/// queue quickly: a fixed-size thumbnail leading a compact metadata line,
/// with the two review actions on their own row so they read as a distinct,
/// deliberate step rather than blending into the card's body text.
class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isReviewing,
    required this.onApprove,
    required this.onReject,
  });

  final VerificationRequest request;
  final bool isReviewing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  void _openFullScreen(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(
                request.documentUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const _ImageError(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _openFullScreen(context),
                child: ClipRRect(
                  borderRadius: AppRadius.controlAll,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Image.network(
                      request.documentUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const ColoredBox(
                          color: Colors.black12,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const _ImageError(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requested by',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      request.userId,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap the image to view full size',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  icon: Icons.close,
                  secondary: true,
                  isLoading: isReviewing,
                  onPressed: isReviewing ? null : onReject,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Approve',
                  icon: Icons.check,
                  isLoading: isReviewing,
                  onPressed: isReviewing ? null : onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: AppStatusIcon(
          icon: Icons.broken_image_outlined,
          size: 40,
          background: Theme.of(context).colorScheme.errorContainer,
          foreground: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
