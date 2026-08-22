import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/utils/validators.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';

/// Owner: Pathirana (features/auth_trust). See [LoginScreen] for the real
/// sign-in pattern this follows.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.elderly;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      final useCase = ref.read(signUpWithEmailUseCaseProvider);
      final result = await useCase(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        role: _role,
      );
      result.fold(
        (failure) => _showMessage(failure.message),
        (user) {
          if (mounted) context.go(RouteNames.home);
        },
      );
    } on UnimplementedError catch (e) {
      _showMessage(e.message ?? 'Sign-up not implemented yet.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create an account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join the community',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'It takes a minute. You can change these details later.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.mail_outline,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Phone',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.phone_outlined,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.lock_outline,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RolePicker(
                      value: _role,
                      onChanged: (role) => setState(() => _role = role),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Create account',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Role selection as a list of always-visible options rather than a dropdown.
///
/// A dropdown hides every choice but one behind an extra tap and a menu that
/// can land off-screen — a poor trade for three fixed options, and a worse one
/// for a user with reduced dexterity. These read as radio buttons to a screen
/// reader and each is well over the 48dp tap minimum.
class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  static IconData _iconFor(UserRole role) => switch (role) {
        UserRole.elderly => Icons.elderly,
        UserRole.volunteer => Icons.volunteer_activism,
        UserRole.admin => Icons.admin_panel_settings_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('I am a...', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        for (final role in UserRole.values) ...[
          _RoleOption(
            label: role.label,
            icon: _iconFor(role),
            selected: role == value,
            onTap: () => onChanged(role),
          ),
          if (role != UserRole.values.last)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        borderRadius: AppRadius.controlAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.controlAll,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.controlAll,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outline,
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                // Selection is carried by a glyph as well as by colour and
                // weight, so it survives colour-blindness and high contrast.
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
