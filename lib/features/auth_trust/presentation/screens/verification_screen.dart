import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';
import 'package:elderly_companion/core/widgets/empty_view.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/core/widgets/loading_view.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/verification_status.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';

/// Owner: Pathirana (features/auth_trust). Lets the signed-in user submit an
/// identity document for review and shows the live status of their latest
/// request via [verificationStatusProvider].
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  bool _isSubmitting = false;

  Future<void> _submitDocument(String userId) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isSubmitting = true);
    try {
      final storagePath =
          '${AppConfig.verificationDocsPath}/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final documentUrl = await ref.read(storageServiceProvider).uploadFile(
            storagePath: storagePath,
            file: File(picked.path),
          );

      final useCase = ref.read(submitVerificationRequestUseCaseProvider);
      final result = await useCase(userId: userId, documentUrl: documentUrl);
      result.fold(
        (failure) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message))),
        (_) => messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Document submitted for review.'))),
      );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not upload document. Try again.')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: authState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: error.toString()),
        data: (user) {
          if (user == null) {
            return const EmptyView(
              icon: Icons.lock_outline,
              title: 'Sign in first',
              message: 'You need to be signed in before you can submit an '
                  'identity document.',
            );
          }
          return _VerificationBody(
            userId: user.id,
            isSubmitting: _isSubmitting,
            onSubmit: () => _submitDocument(user.id),
          );
        },
      ),
    );
  }
}

class _VerificationBody extends ConsumerWidget {
  const _VerificationBody({
    required this.userId,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final String userId;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(verificationStatusProvider(userId));

    return statusAsync.when(
      loading: () => const LoadingView(message: 'Checking your status...'),
      error: (error, _) => ErrorView(message: error.toString()),
      data: (request) {
        final status = request?.status;
        final canSubmit = status != VerificationStatus.pending &&
            status != VerificationStatus.approved;

        return _StatusPanel(
          status: status,
          isSubmitting: isSubmitting,
          onSubmit: canSubmit ? onSubmit : null,
        );
      },
    );
  }
}

/// The verification state rendered as a designed panel rather than a generic
/// empty view: each status gets its own tint, glyph and plain-language copy,
/// so the answer to "am I verified?" is readable at a glance.
class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.status,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final VerificationStatus? status;
  final bool isSubmitting;
  final VoidCallback? onSubmit;

  _StatusVisuals _visuals(ColorScheme scheme) {
    return switch (status) {
      VerificationStatus.approved => _StatusVisuals(
          icon: Icons.verified_user,
          badge: 'Verified',
          title: "You're verified",
          message: 'Your identity has been confirmed. Members you match with '
              'will see your verified badge.',
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        ),
      VerificationStatus.pending => _StatusVisuals(
          icon: Icons.hourglass_top,
          badge: 'Under review',
          title: 'Your document is being checked',
          message: 'Nothing more to do for now — we will let you know as soon '
              'as the review is finished.',
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
        ),
      VerificationStatus.rejected => _StatusVisuals(
          icon: Icons.error_outline,
          badge: 'Not approved',
          title: 'We could not verify that document',
          message: 'Your last submission was rejected. Please submit a new, '
              'clear photo of your identity document.',
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
        ),
      null => _StatusVisuals(
          icon: Icons.badge_outlined,
          badge: 'Not started',
          title: 'Verify your identity',
          message: 'Sharing an identity document helps everyone here trust who '
              'they are meeting. It is only seen by our review team.',
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = _visuals(theme.colorScheme);

    return StatusLayout(
      children: [
        AppStatusIcon(
          icon: visuals.icon,
          background: visuals.background,
          foreground: visuals.foreground,
        ),
        const SizedBox(height: AppSpacing.md),
        _StatusBadge(visuals: visuals),
        const SizedBox(height: AppSpacing.md),
        Text(
          visuals.title,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          visuals.message,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (onSubmit != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Submit document',
            icon: Icons.upload_file_outlined,
            isLoading: isSubmitting,
            onPressed: onSubmit,
          ),
        ],
      ],
    );
  }
}

/// Pill restating the status in words — the tint alone must never be the only
/// thing carrying the meaning.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.visuals});

  final _StatusVisuals visuals;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: visuals.background,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        visuals.badge,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: visuals.foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

@immutable
class _StatusVisuals {
  const _StatusVisuals({
    required this.icon,
    required this.badge,
    required this.title,
    required this.message,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String message;
  final Color background;
  final Color foreground;
}
