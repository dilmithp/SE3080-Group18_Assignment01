import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/notifications/domain/entities/app_notification.dart';
import 'package:elderly_companion/features/notifications/domain/entities/notification_type.dart';

/// Contract for the in-app notification feed: creating a notification for a
/// recipient, watching one user's feed, and flipping the read flag.
///
/// Owner: features/notifications.
abstract class NotificationsRepository {
  /// Writes one notification for [userId]. Any other feature that needs to
  /// tell a user something (a session changed state, feedback arrived)
  /// calls this — see how session_repository_impl.dart and
  /// feedback_repository_impl.dart use it as a best-effort side effect of
  /// their own primary writes.
  Future<Either<Failure, void>> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
  });

  /// Live feed for [userId], newest first.
  Stream<List<AppNotification>> watchNotificationsForUser(String userId);

  Future<Either<Failure, void>> markAsRead(String notificationId);
}
