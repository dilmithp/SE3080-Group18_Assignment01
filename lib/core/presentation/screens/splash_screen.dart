import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/routing/app_router.dart';
import 'package:elderly_companion/core/routing/route_names.dart';

/// First screen shown on launch. Decides whether to land on [RouteNames.home]
/// or [RouteNames.login] based on [isAuthenticatedProvider].
///
/// TODO(Pathirana): once real auth-state restoration exists, this should
/// await it instead of reading the placeholder flag directly.
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
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    context.go(isAuthenticated ? RouteNames.home : RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volunteer_activism,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
