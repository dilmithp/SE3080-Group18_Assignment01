import 'dart:io';

/// Native (Android/iOS/desktop) connectivity check: a lightweight DNS lookup
/// against google.com. Succeeds when online, throws when fully offline.
Future<bool> isOffline() async {
  try {
    final result =
        await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
    return result.isEmpty || result.first.rawAddress.isEmpty;
  } catch (_) {
    return true;
  }
}
