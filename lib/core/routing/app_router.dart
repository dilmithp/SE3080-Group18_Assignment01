import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/presentation/screens/home_screen.dart';
import 'package:elderly_companion/core/presentation/screens/splash_screen.dart';
import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/core/theme/accessibility/accessibility_controller.dart';
import 'package:elderly_companion/core/theme/app_motion.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/app_user.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';
import 'package:elderly_companion/features/auth_trust/presentation/screens/admin_verification_queue_screen.dart';
import 'package:elderly_companion/features/auth_trust/presentation/screens/login_screen.dart';
import 'package:elderly_companion/features/auth_trust/presentation/screens/signup_screen.dart';
import 'package:elderly_companion/features/auth_trust/presentation/screens/verification_screen.dart';
import 'package:elderly_companion/features/community/presentation/screens/community_feed_screen.dart';
import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/matching/presentation/screens/match_details_screen.dart';
import 'package:elderly_companion/features/matching/presentation/screens/matching_screen.dart';
import 'package:elderly_companion/features/messaging/presentation/screens/chat_screen.dart';
import 'package:elderly_companion/features/messaging/presentation/screens/conversations_list_screen.dart';
import 'package:elderly_companion/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:elderly_companion/features/profiles/presentation/screens/accessibility_settings_screen.dart';
import 'package:elderly_companion/features/profiles/presentation/screens/edit_profile_screen.dart';
import 'package:elderly_companion/features/profiles/presentation/screens/profile_screen.dart';
import 'package:elderly_companion/features/scheduling/presentation/screens/scheduling_screen.dart';
import 'package:elderly_companion/features/scheduling/presentation/screens/session_details_screen.dart';
import 'package:elderly_companion/features/scheduling/presentation/screens/session_feedback_screen.dart';
import 'package:elderly_companion/features/scheduling/presentation/screens/session_series_screen.dart';

/// Bridges a Riverpod-watched value into a [Listenable] so [GoRouter] can
/// react to auth-state changes without rebuilding the whole router.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AsyncValue<AppUser?>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<AppUser?>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

String? _redirect(Ref ref, GoRouterState state) {
  final isAuthenticated = ref.read(authStateProvider).valueOrNull != null;
  final location = state.matchedLocation;
  final isAuthRoute = location == RouteNames.login || location == RouteNames.signup;

  if (location == RouteNames.splash) {
    return null;
  }
  if (!isAuthenticated && !isAuthRoute) {
    return RouteNames.login;
  }
  if (isAuthenticated && isAuthRoute) {
    return RouteNames.home;
  }
  return null;
}

/// One transition for every route — a soft fade with a short upward drift,
/// the same [AppMotion] vocabulary used everywhere else in the app, so
/// navigating never feels like a different app took over mid-tap.
///
/// Falls back to an instant cut (no animation at all) when the OS-level
/// reduce-motion setting or this app's own Simplified Mode is on — read via
/// the [ProviderScope] container directly since a route's `pageBuilder`
/// isn't a [ConsumerWidget].
Page<void> _appPage(BuildContext context, GoRouterState state, Widget child) {
  final container = ProviderScope.containerOf(context, listen: false);
  final simplified =
      container.read(accessibilityControllerProvider).simplifiedMode;
  final reduceMotion = simplified || MediaQuery.of(context).disableAnimations;

  if (reduceMotion) {
    return NoTransitionPage(key: state.pageKey, child: child);
  }
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.standard,
    reverseTransitionDuration: AppMotion.exitStandard,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.enter);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        pageBuilder: (context, state) =>
            _appPage(context, state, const SplashScreen()),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        pageBuilder: (context, state) =>
            _appPage(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: RouteNames.signup,
        name: 'signup',
        pageBuilder: (context, state) =>
            _appPage(context, state, const SignupScreen()),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        pageBuilder: (context, state) =>
            _appPage(context, state, const HomeScreen()),
      ),
      GoRoute(
        path: RouteNames.verification,
        name: 'verification',
        pageBuilder: (context, state) =>
            _appPage(context, state, const VerificationScreen()),
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        pageBuilder: (context, state) =>
            _appPage(context, state, const ProfileScreen()),
      ),
      GoRoute(
        path: RouteNames.editProfile,
        name: 'editProfile',
        pageBuilder: (context, state) =>
            _appPage(context, state, const EditProfileScreen()),
      ),
      GoRoute(
        path: RouteNames.accessibilitySettings,
        name: 'accessibilitySettings',
        pageBuilder: (context, state) =>
            _appPage(context, state, const AccessibilitySettingsScreen()),
      ),
      GoRoute(
        path: RouteNames.matching,
        name: 'matching',
        pageBuilder: (context, state) =>
            _appPage(context, state, const MatchingScreen()),
      ),
      GoRoute(
        path: RouteNames.matchDetails,
        name: 'matchDetails',
        pageBuilder: (context, state) => _appPage(
          context,
          state,
          MatchDetailsScreen(
            candidateId: state.pathParameters['candidateId']!,
            candidate: state.extra as MatchCandidate?,
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.scheduling,
        name: 'scheduling',
        pageBuilder: (context, state) =>
            _appPage(context, state, const SchedulingScreen()),
      ),
      GoRoute(
        path: RouteNames.sessionDetails,
        name: 'sessionDetails',
        pageBuilder: (context, state) => _appPage(
          context,
          state,
          SessionDetailsScreen(sessionId: state.pathParameters['sessionId']!),
        ),
      ),
      GoRoute(
        path: RouteNames.sessionFeedback,
        name: 'sessionFeedback',
        pageBuilder: (context, state) => _appPage(
          context,
          state,
          SessionFeedbackScreen(sessionId: state.pathParameters['sessionId']!),
        ),
      ),
      GoRoute(
        path: RouteNames.sessionSeries,
        name: 'sessionSeries',
        pageBuilder: (context, state) => _appPage(
          context,
          state,
          SessionSeriesScreen(seriesId: state.pathParameters['seriesId']!),
        ),
      ),
      GoRoute(
        path: RouteNames.adminVerificationQueue,
        name: 'adminVerificationQueue',
        pageBuilder: (context, state) =>
            _appPage(context, state, const AdminVerificationQueueScreen()),
      ),
      GoRoute(
        path: RouteNames.conversations,
        name: 'conversations',
        pageBuilder: (context, state) =>
            _appPage(context, state, const ConversationsListScreen()),
      ),
      GoRoute(
        path: RouteNames.chat,
        name: 'chat',
        pageBuilder: (context, state) => _appPage(
          context,
          state,
          ChatScreen(
            conversationId: state.pathParameters['conversationId']!,
            otherUserId: state.extra as String,
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.notifications,
        name: 'notifications',
        pageBuilder: (context, state) =>
            _appPage(context, state, const NotificationsScreen()),
      ),
      GoRoute(
        path: RouteNames.community,
        name: 'community',
        pageBuilder: (context, state) =>
            _appPage(context, state, const CommunityFeedScreen()),
      ),
    ],
  );
});
