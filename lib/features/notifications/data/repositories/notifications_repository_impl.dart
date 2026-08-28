import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:elderly_companion/features/notifications/domain/entities/app_notification.dart';
import 'package:elderly_companion/features/notifications/domain/entities/notification_type.dart';
import 'package:elderly_companion/features/notifications/domain/repositories/notifications_repository.dart';

/// Satisfies [NotificationsRepository] by delegating to [_dataSource] and
/// mapping data-layer exceptions to [Failure]s — see
/// verification_repository_impl.dart for the pattern this copies.
class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._dataSource);

  final NotificationsRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, void>> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
  }) async {
    try {
      await _dataSource.createNotification(
        userId: userId,
        type: type.value,
        title: title,
        body: body,
        relatedId: relatedId,
      );
      return const Right(null);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<List<AppNotification>> watchNotificationsForUser(String userId) {
    return _dataSource
        .watchNotificationsForUser(userId)
        .map((dtos) => dtos.map((d) => d.toEntity()).toList());
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await _dataSource.markAsRead(notificationId);
      return const Right(null);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
