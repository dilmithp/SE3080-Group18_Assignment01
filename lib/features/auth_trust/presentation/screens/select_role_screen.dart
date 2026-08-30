import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/auth_trust/presentation/widgets/role_picker.dart';

/// Shown once, immediately after a brand-new passwordless email-link sign-in
/// (see `AuthTrustRemoteDataSource.signInWithEmailLink`), to let the user
/// correct the [UserRole.elderly] placeholder that flow has no form to
/// collect a real value for. Not a named `go_router` route — pushed via a
/// plain [Navigator.push] from [SplashScreen] as part of that one-time
/// completion sequence, then popped once the role is saved.
///
/// [onDone] is called after a successful save (or if the user is allowed to
/// skip) so the caller can continue its own navigation — this screen never
/// navigates on its own.
class SelectRoleScreen extends ConsumerStatefulWidget {
  const SelectRoleScreen({
    required this.userId,
    required this.onDone,
    this.initialRole = UserRole.elderly,
    super.key,
  });

  final String userId;
  final UserRole initialRole;
  final VoidCallback onDone;

  @override
  ConsumerState<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends ConsumerState<SelectRoleScreen> {
  late UserRole _role = widget.initialRole;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _confirm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final useCase = ref.read(updateUserRoleUseCaseProvider);
    final result = await useCase(userId: widget.userId, role: _role);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isSubmitting = false;
        _errorMessage = failure.message;
      }),
      (_) => widget.onDone(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // No back button: this is a mandatory one-time step for a brand-new
    // account, not a page the user should be able to abandon into a
    // half-set-up profile.
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "You're signed in",
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tell us which of these best describes you, so we can '
                    'set up the right experience.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  RolePicker(
                    value: _role,
                    onChanged: (role) => setState(() => _role = role),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Continue',
                    isLoading: _isSubmitting,
                    onPressed: _confirm,
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
