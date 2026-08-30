import 'package:shared_preferences/shared_preferences.dart';

const _prefsKeyPendingSignInEmail = 'auth_trust.pendingEmailLinkAddress';

/// Persists the address a passwordless sign-in link was sent to, so
/// completing sign-in on the same browser (see [SplashScreen]) doesn't need
/// the user to retype it. Mirrors the direct `SharedPreferences.getInstance()`
/// per-call pattern used by `AccessibilityController` rather than caching an
/// instance — this is read/written rarely enough that it doesn't matter.
class EmailLinkPrefs {
  const EmailLinkPrefs._();

  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyPendingSignInEmail, email);
  }

  static Future<String?> readEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyPendingSignInEmail);
  }

  static Future<void> clearEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyPendingSignInEmail);
  }
}
