/// Maps a FirebaseAuth error code to a message the user can act on. Codes
/// not listed here keep [fallback].
String friendlyAuthMessage(String? code, String fallback) {
  switch (code) {
    case 'too-many-requests':
      return 'Too many attempts. Wait a few minutes, or reset your password.';
    case 'network-request-failed':
      return 'No network connection. Check your connection and try again.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support.';
    default:
      return fallback;
  }
}
