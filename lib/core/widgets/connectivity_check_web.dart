/// Web stub: `dart:io`'s `InternetAddress.lookup` doesn't exist on web, and
/// the project hasn't taken a `connectivity_plus` dependency. Always reports
/// online — [OfflineBanner] simply never shows on web, same behavior as the
/// `kIsWeb` early-return this replaces.
Future<bool> isOffline() async => false;
