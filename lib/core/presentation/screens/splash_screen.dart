import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/utils/validators.dart';
import 'package:elderly_companion/core/widgets/app_brand_mark.dart';
import 'package:elderly_companion/core/widgets/app_button.dart';
import 'package:elderly_companion/core/widgets/app_text_field.dart';
import 'package:elderly_companion/core/widgets/error_view.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/email_link_prefs.dart';
import 'package:elderly_companion/features/auth_trust/presentation/screens/select_role_screen.dart';

/// First screen shown on launch. Awaits the first real Firebase auth-state
/// emission (see [authStateProvider]) then lands on [RouteNames.home] or
/// [RouteNames.login] accordingly.
///
/// Also the startup hook for passwordless email-link sign-in
/// (`AuthRepository.sendSignInLinkToEmail` /
/// `EmailLinkSignInScreen`): on web, opening the emailed link reloads the
/// app at its own origin with Firebase's sign-in parameters attached to the
/// URL, so this is the one place that has to notice that before falling
/// back to the ordinary auth-state redirect below.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Set only when email-link completion fails (expired/invalid link) — the
  /// build method swaps to [ErrorView] instead of the normal splash content
  /// so the user sees a clear, actionable message rather than being stuck on
  /// a spinner or crashing silently.
  String? _emailLinkError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    final authRepository = ref.read(authRepositoryProvider);
    // Uri.base is the browser address bar on web; on other platforms it's
    // the executable's own URI, which will never match a sign-in link, so
    // this check is a no-op there.
    final currentUrl = Uri.base.toString();

    if (authRepository.isSignInWithEmailLink(currentUrl)) {
      await _completeEmailLinkSignIn(currentUrl);
      return;
    }

    final user = await ref.read(authStateProvider.future);
    if (!mounted) return;
    context.go(user != null ? RouteNames.home : RouteNames.login);
  }

  Future<void> _completeEmailLinkSignIn(String link) async {
    var email = await EmailLinkPrefs.readEmail();

    if (email == null) {
      // Link opened in a different browser/session than the one it was
      // requested from — ask for the address rather than getting stuck.
      if (!mounted) return;
      email = await _promptForEmail();
      if (email == null) {
        if (!mounted) return;
        context.go(RouteNames.login);
        return;
      }
    }

    final useCase = ref.read(signInWithEmailLinkUseCaseProvider);
    final result = await useCase(email: email, emailLink: link);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() => _emailLinkError = failure.message),
      (user) {
        // Clearing the stored email here means a page refresh won't try to
        // replay this link. The browser URL itself is cleared as a
        // side effect of the `context.go` calls below: go_router rewrites
        // the address bar to the new location, dropping the old sign-in
        // query parameters with it.
        EmailLinkPrefs.clearEmail();

        // signInWithEmailLink has no way to report "this uid's users/{uid}
        // doc was just created" through its Either<Failure, AppUser> return
        // type, so this is a heuristic rather than an exact signal: a
        // genuinely brand-new doc's createdAt is whatever `Timestamp.now()`
        // was at the moment this very call created it, i.e. seconds ago. An
        // existing user signing in again via the same flow will have a much
        // older createdAt. See auth_repository.dart's updateUserRole doc
        // comment for the rest of this flow.
        final isLikelyNewUser =
            DateTime.now().difference(user.createdAt) < const Duration(seconds: 20);

        if (!mounted) return;
        if (isLikelyNewUser) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SelectRoleScreen(
                userId: user.id,
                initialRole: user.role,
                onDone: () {
                  Navigator.of(context).pop();
                  context.go(RouteNames.home);
                },
              ),
            ),
          );
          return;
        }
        context.go(RouteNames.home);
      },
    );
  }

  /// Blocking dialog asking for the email a sign-in link was requested with.
  /// Only shown when [EmailLinkPrefs] has nothing stored for this browser.
  Future<String?> _promptForEmail() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final email = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm your email'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter the email address you requested the sign-in link '
                  'with, so we can finish signing you in.',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Email',
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  textInputAction: TextInputAction.done,
                  validator: Validators.email,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Continue',
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
            ),
          ],
        );
      },
    );
    controller.dispose();
    return email;
  }

  @override
  Widget build(BuildContext context) {
    final emailLinkError = _emailLinkError;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxProseWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: emailLinkError != null
                ? ErrorView(
                    title: "That link didn't work",
                    message: emailLinkError,
                    onRetry: () {
                      setState(() => _emailLinkError = null);
                      context.go(RouteNames.login);
                    },
                  )
                // A short fade keeps the launch from snapping into place. It
                // is decorative only — the redirect above does not wait on
                // it.
                : TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    builder: (context, value, child) =>
                        Opacity(opacity: value, child: child),
                    child: const _SplashContent(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBrandMark(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppConfig.appName,
          style: theme.textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Companionship and a helping hand, close to home.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3.5),
        ),
      ],
    );
  }
}
