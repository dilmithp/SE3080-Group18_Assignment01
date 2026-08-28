import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/features/notifications/data/models/app_notification_dto.dart';

/// Firestore collection name for this feature. Kept local to this file
/// rather than added to `AppConfig` — that file sits outside this
/// feature's boundary for this change; a later pass can promote it to
/// `AppConfig.notificationsCollection` alongside the other collection
/// constants if it wants one central list.
const String _notificationsCollection = 'notifications';

/// Raw Firebase calls for the in-app notification feed. Throws the
/// exceptions in core/error/exceptions.dart; [NotificationsRepositoryImpl]
/// translates those into [Failure]s.
abstract class NotificationsRemoteDataSource {
  Future<AppNotificationDto> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedId,
  });

  Stream<List<AppNotificationDto>> watchNotificationsForUser(String userId);

  Future<void> markAsRead(String notificationId);
}

class FirebaseNotificationsRemoteDataSource
    implements NotificationsRemoteDataSource {
  FirebaseNotificationsRemoteDataSource({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  @override
  Future<AppNotificationDto> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedId,
  }) async {
    try {
      final id = _firestoreService.newDocId(_notificationsCollection);
      final createdAt = Timestamp.now();
      await _firestoreService.setDocument(
        collectionPath: _notificationsCollection,
        docId: id,
        data: {
          'userId': userId,
          'type': type,
          'title': title,
          'body': body,
          'relatedId': relatedId,
          'isRead': false,
          'createdAt': createdAt,
        },
      );
      return AppNotificationDto(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        relatedId: relatedId,
        isRead: false,
        createdAtMillis: createdAt.toDate().millisecondsSinceEpoch,
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<List<AppNotificationDto>> watchNotificationsForUser(String userId) {
    return _firestoreService
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _dtoFromData(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      final docRef =
          _firestoreService.collection(_notificationsCollection).doc(notificationId);
      final existing = await docRef.get();
      if (existing.data() == null) {
        throw const NotFoundException('Notification not found.');
      }
      await _firestoreService.setDocument(
        collectionPath: _notificationsCollection,
        docId: notificationId,
        data: {'isRead': true},
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } on NotFoundException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  AppNotificationDto _dtoFromData(String id, Map<String, dynamic> data) {
    return AppNotificationDto(
      id: id,
      userId: data['userId'] as String,
      type: data['type'] as String,
      title: data['title'] as String,
      body: data['body'] as String,
      relatedId: data['relatedId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAtMillis: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
    );
  }
}
