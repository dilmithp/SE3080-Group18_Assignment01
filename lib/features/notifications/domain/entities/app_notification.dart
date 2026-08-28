import 'package:elderly_companion/features/notifications/domain/entities/notification_type.dart';

/// Pure domain entity — zero `package:firebase_*` imports. Data-layer DTOs
/// (see data/models/app_notification_dto.dart) convert Firestore documents
/// to and from this type; nothing outside data/ should know Firestore
/// exists.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.relatedId,
  });

  final String id;

  /// The recipient — whoever should see this in their notification feed.
  /// Not necessarily the user who triggered the underlying event.
  final String userId;

  final NotificationType type;
  final String title;
  final String body;

  /// Id of the thing this notification is about (e.g. a sessionId). Null
  /// for notifications with nothing to deep-link to.
  final String? relatedId;

  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          type == other.type &&
          title == other.title &&
          body == other.body &&
          relatedId == other.relatedId &&
          isRead == other.isRead &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        type,
        title,
        body,
        relatedId,
        isRead,
        createdAt,
      );
}
