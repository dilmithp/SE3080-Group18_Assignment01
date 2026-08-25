import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/notifications/domain/entities/notification_type.dart';
import 'package:elderly_companion/features/notifications/domain/repositories/notifications_repository.dart';

/// Single business rule: raise one notification for a recipient.
class CreateNotificationUseCase {
  const CreateNotificationUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, void>> call({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
  }) {
    return _repository.createNotification(
      userId: userId,
      type: type,
      title: title,
      body: body,
      relatedId: relatedId,
    );
  }
}
