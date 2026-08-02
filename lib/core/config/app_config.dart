/// Environment flags and Firestore collection name constants.
///
/// Centralising collection names here means a rename is a one-line change
/// instead of a project-wide find/replace across every data source.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Elderly Companion';

  /// Toggle for verbose logging during development.
  static const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String verificationRequestsCollection = 'verification_requests';
  static const String trustScoresCollection = 'trust_scores';
  static const String profilesCollection = 'profiles';
  static const String sessionsCollection = 'sessions';
  static const String sessionFeedbackCollection = 'session_feedback';

  // Storage paths
  static const String verificationDocsPath = 'verification_documents';
  static const String profilePhotosPath = 'profile_photos';
}
