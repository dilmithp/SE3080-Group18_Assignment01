import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:elderly_companion/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:elderly_companion/features/notifications/domain/entities/app_notification.dart';
import 'package:elderly_companion/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:elderly_companion/features/notifications/domain/usecases/create_notification_usecase.dart';
import 'package:elderly_companion/features/notifications/domain/usecases/mark_notification_read_usecase.dart';

/// All Dependency-Inversion wiring for notifications lives here:
/// presentation and domain depend only on the abstract repository
/// interface above; this file is the only place that knows
/// [NotificationsRepositoryImpl] etc. exist.

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
  return FirebaseNotificationsRemoteDataSource(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(ref.watch(notificationsRemoteDataSourceProvider));
});

final createNotificationUseCaseProvider = Provider<CreateNotificationUseCase>((ref) {
  return CreateNotificationUseCase(ref.watch(notificationsRepositoryProvider));
});

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>((ref) {
  return MarkNotificationReadUseCase(ref.watch(notificationsRepositoryProvider));
});

/// Live feed for one user, newest first.
final notificationsForUserProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
  return ref.watch(notificationsRepositoryProvider).watchNotificationsForUser(userId);
});

/// Unread count derived from [notificationsForUserProvider] rather than a
/// second Firestore read — the feed already carries every notification the
/// badge needs to count. Falls back to 0 while loading or on error so the
/// bell never shows a stale or crashing count.
final unreadNotificationCountProvider = Provider.family<int, String>((ref, userId) {
  final notifications = ref.watch(notificationsForUserProvider(userId));
  return notifications.maybeWhen(
    data: (items) => items.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
