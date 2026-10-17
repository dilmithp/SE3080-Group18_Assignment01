import 'package:elderly_companion/core/routing/route_names.dart';

/// Maps a push notification's data payload to an app route, so every feature's
/// notifications are routed from one place. Returns null when the payload is
/// unknown or incomplete, and the app then opens its default screen.
///
/// Ids come from the payload, so they are checked before being put into a
/// path: a value with a slash or query character could otherwise point the
/// app at a different route.
String? routeForNotification(Map<String, String> data) {
  switch (data['type']) {
    case 'session_reminder':
      final sessionId = _safeId(data['sessionId']);
      return sessionId == null
          ? null
          : RouteNames.sessionDetails.replaceFirst(':sessionId', sessionId);
    case 'verification_approved':
    case 'verification_rejected':
      return RouteNames.verification;
    default:
      return null;
  }
}

/// [routeForNotification] for a raw push payload, whose values may not be
/// strings. Non-string values are dropped.
String? routeForPushData(Map<String, dynamic> data) {
  final strings = <String, String>{
    for (final entry in data.entries)
      if (entry.value is String) entry.key: entry.value as String,
  };
  return routeForNotification(strings);
}

String? _safeId(String? id) {
  if (id == null || id.isEmpty) return null;
  final allowed = RegExp(r'^[A-Za-z0-9_-]+$');
  return allowed.hasMatch(id) ? id : null;
}
