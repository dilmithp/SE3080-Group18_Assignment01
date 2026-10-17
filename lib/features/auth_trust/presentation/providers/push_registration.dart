import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/core/routing/app_router.dart';
import 'package:elderly_companion/core/routing/notification_route.dart';
import 'package:elderly_companion/features/auth_trust/presentation/providers/auth_providers.dart';

/// Keeps the signed-in user's push token saved on users/{uid}.fcmToken, so
/// the reminder scheduler can push to this device, and opens the right screen
/// when a push is tapped.
///
/// Must be watched once from the app root (see app.dart). Failures are logged
/// and otherwise ignored: web push needs a VAPID key and service worker, and a
/// device that refuses permission should still be usable.
///
/// Owner: Pathirana (features/auth_trust).
final pushRegistrationProvider = Provider<void>((ref) {
  final notifications = ref.watch(notificationServiceProvider);
  final firestore = ref.watch(firestoreServiceProvider);

  Future<void> saveToken(String userId, String token) async {
    try {
      await firestore.setDocument(
        collectionPath: AppConfig.usersCollection,
        docId: userId,
        data: {'fcmToken': token},
        merge: true,
      );
    } catch (error) {
      debugPrint('Saving push token failed: $error');
    }
  }

  Future<void> registerCurrentDevice(String userId) async {
    try {
      await notifications.requestPermission();
      final token = await notifications.getToken();
      if (token != null) await saveToken(userId, token);
    } catch (error) {
      debugPrint('Push registration skipped: $error');
    }
  }

  void openRoute(Map<String, dynamic> data) {
    final route = routeForPushData(data);
    if (route != null) ref.read(goRouterProvider).go(route);
  }

  ref.listen(authStateProvider, (_, next) {
    final user = next.valueOrNull;
    if (user != null) registerCurrentDevice(user.id);
  });

  final tokenRefresh = notifications.onTokenRefresh.listen((token) {
    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId != null) saveToken(userId, token);
  });

  final tapped = notifications.onMessageOpenedApp.listen(
    (message) => openRoute(message.data),
  );

  notifications.getInitialMessage().then((message) {
    if (message != null) openRoute(message.data);
  }).catchError((Object error) {
    debugPrint('Initial push check failed: $error');
  });

  ref.onDispose(() {
    tokenRefresh.cancel();
    tapped.cancel();
  });
});
