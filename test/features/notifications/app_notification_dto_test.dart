import 'package:elderly_companion/features/notifications/data/models/app_notification_dto.dart';
import 'package:elderly_companion/features/notifications/domain/entities/app_notification.dart';
import 'package:elderly_companion/features/notifications/domain/entities/notification_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotificationDto <-> AppNotification', () {
    test('fromEntity/toEntity round-trips every field', () {
      final entity = AppNotification(
        id: 'notif-1',
        userId: 'user-2',
        type: NotificationType.sessionCancelled,
        title: 'Session cancelled',
        body: 'Your session on Fri, 2 Jan · 3:00 PM was cancelled.',
        relatedId: 'session-1',
        isRead: true,
        createdAt: DateTime(2026, 1, 1, 9, 30),
      );

      final dto = AppNotificationDto.fromEntity(entity);

      expect(dto.type, 'session_cancelled');
      expect(dto.toEntity(), entity);
    });

    test('relatedId is nullable end to end', () {
      final entity = AppNotification(
        id: 'notif-2',
        userId: 'user-3',
        type: NotificationType.other,
        title: 'Welcome',
        body: 'Thanks for joining.',
        isRead: false,
        createdAt: DateTime(2026, 1, 1),
      );

      final roundTripped = AppNotificationDto.fromEntity(entity).toEntity();

      expect(roundTripped.relatedId, isNull);
      expect(roundTripped, entity);
    });

    test('an unrecognised stored type string falls back to NotificationType.other', () {
      const dto = AppNotificationDto(
        id: 'notif-3',
        userId: 'user-4',
        type: 'some_future_type',
        title: 'Something new',
        body: 'A type this build does not know about.',
        isRead: false,
        createdAtMillis: 0,
      );

      expect(dto.toEntity().type, NotificationType.other);
    });
  });

  group('NotificationType.fromValue', () {
    test('maps every known Firestore string to its enum value', () {
      expect(
        NotificationType.fromValue('session_confirmed'),
        NotificationType.sessionConfirmed,
      );
      expect(
        NotificationType.fromValue('session_cancelled'),
        NotificationType.sessionCancelled,
      );
      expect(
        NotificationType.fromValue('session_completed'),
        NotificationType.sessionCompleted,
      );
      expect(
        NotificationType.fromValue('feedback_received'),
        NotificationType.feedbackReceived,
      );
    });
  });
}
