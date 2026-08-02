/// Central registry of route paths and names used by [go_router].
///
/// Adding a screen means adding one constant here and one `GoRoute` in
/// app_router.dart — nowhere else should a route path be hardcoded.
class RouteNames {
  const RouteNames._();

  // Core
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';

  // auth_trust
  static const String verification = '/verification';

  // profiles
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // matching
  static const String matching = '/matching';
  static const String matchDetails = '/matching/:candidateId';

  // scheduling
  static const String scheduling = '/scheduling';
  static const String sessionDetails = '/scheduling/:sessionId';
  static const String sessionFeedback = '/scheduling/:sessionId/feedback';

  static String matchDetailsPath(String candidateId) => '/matching/$candidateId';

  static String sessionDetailsPath(String sessionId) => '/scheduling/$sessionId';

  static String sessionFeedbackPath(String sessionId) =>
      '/scheduling/$sessionId/feedback';
}
