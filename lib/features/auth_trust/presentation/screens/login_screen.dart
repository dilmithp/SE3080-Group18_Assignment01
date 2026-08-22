import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/utils/validators.dart';
import 'package:elderly_companion/core/widgets/app_brand_mark.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';

/// Owner: Pathirana (features/auth_trust). Real sign-in via
/// [SignInWithEmailUseCase] — successful sign-in updates [authStateProvider]
/// via Firebase, which drives the router's redirect guard automatically;
/// the explicit `context.go` below just avoids waiting on that round-trip
/// for the immediate UX.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      final useCase = ref.read(signInWithEmailUseCaseProvider);
      final result = await useCase(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      result.fold(
        (failure) => _showMessage(failure.message),
        (user) {
          if (mounted) context.go(RouteNames.home);
        },
      );
    } on UnimplementedError catch (e) {
      _showMessage(e.message ?? 'Sign-in not implemented yet.');
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

    // No app bar: login is a root `go` destination with nothing to go back
    // to, so an empty bar would only cost vertical space on the one screen
    // that should feel like a front door.
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppBrandMark(size: 88)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Welcome back',
                      style: theme.textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sign in to see your matches and upcoming sessions.',
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
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.lock_outline,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Sign in',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'New to Elderly Companion?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      onPressed: () => context.push(RouteNames.signup),
                      child: const Text('Create an account'),
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
