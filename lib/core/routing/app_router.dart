import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elderly_companion/core/presentation/screens/home_screen.dart';
import 'package:elderly_companion/core/presentation/screens/splash_screen.dart';
import 'package:elderly_companion/core/routing/route_names.dart';
import 'package:elderly_companion/features/auth_trust/presentation/screens/login_screen.dart';
import 'package:elderly_companion/features/auth_trust/presentation/screens/signup_screen.dart';
import 'package:elderly_companion/features/auth_trust/presentation/screens/verification_screen.dart';
import 'package:elderly_companion/features/matching/presentation/screens/match_details_screen.dart';
import 'package:elderly_companion/features/matching/presentation/screens/matching_screen.dart';
import 'package:elderly_companion/features/profiles/presentation/screens/edit_profile_screen.dart';
import 'package:elderly_companion/features/profiles/presentation/screens/profile_screen.dart';
import 'package:elderly_companion/features/scheduling/presentation/screens/scheduling_screen.dart';
import 'package:elderly_companion/features/scheduling/presentation/screens/session_details_screen.dart';
import 'package:elderly_companion/features/scheduling/presentation/screens/session_feedback_screen.dart';

/// Placeholder, in-memory auth flag driving the redirect guard below.
///
/// TODO(Pathirana): once `AuthRepository.authStateChanges()` is implemented,
/// replace this with a `StreamProvider<AppUser?>` from auth_trust and update
/// [_redirect] / [_RouterRefreshNotifier] to listen to it instead. Kept as a
/// standalone core provider for now so the router — and every other
/// feature's navigation — isn't blocked on auth_trust's implementation.
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

/// Bridges a Riverpod-watched value into a [Listenable] so [GoRouter] can
/// react to auth-state changes without rebuilding the whole router.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    _subscription = ref.listen<bool>(
      isAuthenticatedProvider,
      (_, __) => notifyListeners(),
    );
  }

  late final ProviderSubscription<bool> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

String? _redirect(Ref ref, GoRouterState state) {
  final isAuthenticated = ref.read(isAuthenticatedProvider);
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
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.verification,
        name: 'verification',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.matching,
        name: 'matching',
        builder: (context, state) => const MatchingScreen(),
      ),
      GoRoute(
        path: RouteNames.matchDetails,
        name: 'matchDetails',
        builder: (context, state) => MatchDetailsScreen(
          candidateId: state.pathParameters['candidateId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.scheduling,
        name: 'scheduling',
        builder: (context, state) => const SchedulingScreen(),
      ),
      GoRoute(
        path: RouteNames.sessionDetails,
        name: 'sessionDetails',
        builder: (context, state) => SessionDetailsScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.sessionFeedback,
        name: 'sessionFeedback',
        builder: (context, state) => SessionFeedbackScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
    ],
  );
});
