import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elderly_companion/core/config/app_config.dart';
import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/features/sos/data/models/sos_alert_dto.dart';

/// Raw Firestore calls for the SOS feature. Throws the exceptions in
/// core/error/exceptions.dart; [SosRepositoryImpl] translates those into
/// [Failure]s.
abstract class SosRemoteDataSource {
  Future<SosAlertDto> triggerAlert({
    required String userId,
    double? latitude,
    double? longitude,
    String? note,
  });

  Stream<SosAlertDto?> watchMyActiveAlert(String userId);

  Stream<List<SosAlertDto>> watchActiveAlerts();

  Future<SosAlertDto> resolveAlert({
    required String alertId,
    required String resolvedBy,
  });
}

class FirebaseSosRemoteDataSource implements SosRemoteDataSource {
  FirebaseSosRemoteDataSource({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  SosAlertDto _fromData(String id, Map<String, dynamic> data) {
    return SosAlertDto(
      id: id,
      userId: data['userId'] as String,
      triggeredAtMillis: (data['triggeredAt'] as Timestamp).millisecondsSinceEpoch,
      status: data['status'] as String,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      note: data['note'] as String?,
      resolvedBy: data['resolvedBy'] as String?,
      resolvedAtMillis: (data['resolvedAt'] as Timestamp?)?.millisecondsSinceEpoch,
    );
  }

  @override
  Future<SosAlertDto> triggerAlert({
    required String userId,
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    try {
      final id = _firestoreService.newDocId(AppConfig.sosAlertsCollection);
      final triggeredAt = Timestamp.now();
      await _firestoreService.setDocument(
        collectionPath: AppConfig.sosAlertsCollection,
        docId: id,
        data: {
          'userId': userId,
          'triggeredAt': triggeredAt,
          'status': 'active',
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return SosAlertDto(
        id: id,
        userId: userId,
        triggeredAtMillis: triggeredAt.millisecondsSinceEpoch,
        status: 'active',
        latitude: latitude,
        longitude: longitude,
        note: note,
      );
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<SosAlertDto?> watchMyActiveAlert(String userId) {
    return _firestoreService
        .collection(AppConfig.sosAlertsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return _fromData(doc.id, doc.data());
    });
  }

  @override
  Stream<List<SosAlertDto>> watchActiveAlerts() {
    return _firestoreService
        .collection(AppConfig.sosAlertsCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('triggeredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _fromData(doc.id, doc.data())).toList(),
        );
  }

  @override
  Future<SosAlertDto> resolveAlert({
    required String alertId,
    required String resolvedBy,
  }) async {
    try {
      final docRef =
          _firestoreService.collection(AppConfig.sosAlertsCollection).doc(alertId);
      final snapshot = await docRef.get();
      final data = snapshot.data();
      if (data == null) {
        throw const NotFoundException('SOS alert not found.');
      }
      final resolvedAt = Timestamp.now();
      await docRef.set(
        {
          'status': 'resolved',
          'resolvedBy': resolvedBy,
          'resolvedAt': resolvedAt,
        },
        SetOptions(merge: true),
      );
      return _fromData(alertId, {...data, 'status': 'resolved', 'resolvedBy': resolvedBy, 'resolvedAt': resolvedAt});
    } on NotFoundException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }
}
