import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/notifications/domain/entities/app_notification.dart';
import 'package:elderly_companion/features/notifications/domain/entities/notification_type.dart';

part 'app_notification_dto.freezed.dart';
part 'app_notification_dto.g.dart';

/// Firestore-shaped DTO for the `notifications` collection. Converts to/from
/// the pure [AppNotification] domain entity — see [toEntity] /
/// [AppNotificationDto.fromEntity]. `createdAt` is stored as epoch
/// milliseconds so this class stays plain-JSON; the data source bridges
/// Firestore's `Timestamp` type at the boundary (see
/// notifications_remote_data_source.dart), the same split
/// scheduling_remote_data_source.dart uses.
@freezed
class AppNotificationDto with _$AppNotificationDto {
  const AppNotificationDto._();

  const factory AppNotificationDto({
    required String id,
    required String userId,
    required String type,
    required String title,
    required String body,
    required bool isRead,
    required int createdAtMillis,
    String? relatedId,
  }) = _AppNotificationDto;

  factory AppNotificationDto.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationDtoFromJson(json);

  factory AppNotificationDto.fromEntity(AppNotification entity) =>
      AppNotificationDto(
        id: entity.id,
        userId: entity.userId,
        type: entity.type.value,
        title: entity.title,
        body: entity.body,
        relatedId: entity.relatedId,
        isRead: entity.isRead,
        createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      );

  AppNotification toEntity() => AppNotification(
        id: id,
        userId: userId,
        type: NotificationType.fromValue(type),
        title: title,
        body: body,
        relatedId: relatedId,
        isRead: isRead,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      );
}
