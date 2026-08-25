import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/notifications/domain/repositories/notifications_repository.dart';

/// Single business rule: flip one notification's read flag.
class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, void>> call(String notificationId) {
    return _repository.markAsRead(notificationId);
  }
}
