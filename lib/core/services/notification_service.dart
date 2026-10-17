import 'package:firebase_messaging/firebase_messaging.dart';

/// Thin wrapper around [FirebaseMessaging]. Handles permission requests and
/// token retrieval only — routing an incoming push to a specific screen is
/// each feature's responsibility (subscribe to [onMessage] from
/// presentation-layer code, don't add feature logic here).
class NotificationService {
  NotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// A push the user tapped while the app was in the background.
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;

  /// The push that launched the app from a terminated state, if any.
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
