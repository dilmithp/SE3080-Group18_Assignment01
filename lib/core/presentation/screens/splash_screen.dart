import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/widgets/app_brand_mark.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';

/// First screen shown on launch. Awaits the first real Firebase auth-state
/// emission (see [authStateProvider]) then lands on [RouteNames.home] or
/// [RouteNames.login] accordingly.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    final user = await ref.read(authStateProvider.future);
    if (!mounted) return;
    context.go(user != null ? RouteNames.home : RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxProseWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            // A short fade keeps the launch from snapping into place. It is
            // decorative only — the redirect above does not wait on it.
            child: TweenAnimationBuilder<double>(
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
