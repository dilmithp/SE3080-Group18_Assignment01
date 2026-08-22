import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/routing/app_router.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/app_theme.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/accessibility_profile_sync.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final accessibility = ref.watch(accessibilityControllerProvider);
    // Keeps AccessibilityProfileSync alive so it can seed local accessibility
    // state from the signed-in user's persisted profile — see that class for
    // why this composition root is the one place allowed to wire core/theme
    // together with a feature.
    ref.watch(accessibilityProfileSyncProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(
        highContrast: accessibility.highContrast,
        simplifiedMode: accessibility.simplifiedMode,
      ),
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(accessibility.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
