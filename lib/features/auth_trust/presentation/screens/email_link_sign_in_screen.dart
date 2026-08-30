import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/utils/validators.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';
import 'package:elderly_companion/core/widgets/app_status_icon.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/email_link_prefs.dart';

/// Passwordless sign-in: enter an email, get a link, come back to this app
/// with it (see [SplashScreen] for the completion side of this flow).
///
/// Reached from [LoginScreen] via a plain [Navigator.push] rather than
/// `context.push` — this feature is not registered as a named route in
/// `app_router.dart`, and adding one is outside auth_trust's file boundary.
/// Pushing a plain [MaterialPageRoute] on top of go_router's own Navigator
/// works fine for a self-contained sub-flow like this one.
class EmailLinkSignInScreen extends ConsumerStatefulWidget {
  const EmailLinkSignInScreen({super.key});

  @override
  ConsumerState<EmailLinkSignInScreen> createState() =>
      _EmailLinkSignInScreenState();
}

class _EmailLinkSignInScreenState extends ConsumerState<EmailLinkSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _sentTo;

  @override
  void initState() {
    super.initState();
    // Prefill with whatever address was last used for this flow, in case the
    // user is re-requesting a link (e.g. the first one expired).
    EmailLinkPrefs.readEmail().then((email) {
      if (email != null && mounted) {
        _emailController.text = email;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    setState(() => _isSubmitting = true);
    try {
      final useCase = ref.read(sendSignInLinkUseCaseProvider);
      final result = await useCase(email);
      await result.fold(
        (failure) async => _showMessage(failure.message),
        (_) async {
          await EmailLinkPrefs.saveEmail(email);
          if (mounted) setState(() => _sentTo = email);
        },
      );
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
    final sentTo = _sentTo;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with email link')),
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
              child: sentTo == null
                  ? _RequestLinkForm(
                      formKey: _formKey,
                      emailController: _emailController,
                      isSubmitting: _isSubmitting,
                      onSubmit: _sendLink,
                    )
                  : _LinkSentConfirmation(
                      email: sentTo,
                      onUseDifferentEmail: () =>
                          setState(() => _sentTo = null),
                      onResend: _isSubmitting
                          ? null
                          : () {
                              setState(() => _sentTo = null);
                              _sendLink();
                            },
                      theme: theme,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestLinkForm extends StatelessWidget {
  const _RequestLinkForm({
    required this.formKey,
    required this.emailController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No password needed',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Enter your email and we'll send you a link that signs you in "
            'on this device — nothing to type or remember.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Email',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.mail_outline,
            validator: Validators.email,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Send sign-in link',
            isLoading: isSubmitting,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _LinkSentConfirmation extends StatelessWidget {
  const _LinkSentConfirmation({
    required this.email,
    required this.onUseDifferentEmail,
    required this.onResend,
    required this.theme,
  });

  final String email;
  final VoidCallback onUseDifferentEmail;
  final VoidCallback? onResend;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppStatusIcon(icon: Icons.mark_email_read_outlined),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Check your email',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'We sent a sign-in link to $email. Open it on this device to '
            'finish signing in.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Resend link',
            icon: Icons.refresh,
            secondary: true,
            onPressed: onResend,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onUseDifferentEmail,
            child: const Text('Use a different email'),
          ),
        ],
      ),
    );
  }
}
