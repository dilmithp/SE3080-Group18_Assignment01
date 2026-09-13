import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/routing/app_router.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/app_theme.dart';
import 'package:elderly_companion/core/widgets/offline_banner.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/push_registration.dart';
import 'package:elderly_companion/features/profiles/presentation/providers/accessibility_profile_sync.dart';
import 'package:elderly_companion/l10n/app_localizations.dart';

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
    ref.watch(pushRegistrationProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(
        highContrast: accessibility.highContrast,
        simplifiedMode: accessibility.simplifiedMode,
      ),
      locale: accessibility.languageCode == null
          ? null
          : Locale(accessibility.languageCode!),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(accessibility.textScale),
            // Folded in here (rather than only checked by AppMotion.reduced)
            // so every widget that already respects the OS "reduce motion"
            // setting — not just this app's own motion-aware code — also
            // respects the user's explicit in-app toggle.
            disableAnimations: accessibility.reducedMotion ||
                accessibility.simplifiedMode ||
                mediaQuery.disableAnimations,
          ),
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}
