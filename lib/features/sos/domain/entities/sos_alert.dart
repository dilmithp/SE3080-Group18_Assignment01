import 'package:elderly_companion/features/sos/domain/entities/sos_alert_status.dart';

/// Pure domain entity — zero `package:firebase_*` imports.
///
/// One emergency alert a user triggered from [SosButton]. [latitude]/
/// [longitude] are best-effort: a user who denied location permission, or
/// whose device couldn't get a fix in time, still gets an alert created
/// with both null rather than being blocked from alerting at all.
class SosAlert {
  const SosAlert({
    required this.id,
    required this.userId,
    required this.triggeredAt,
    required this.status,
    this.latitude,
    this.longitude,
    this.note,
    this.resolvedBy,
    this.resolvedAt,
  });

  final String id;
  final String userId;
  final DateTime triggeredAt;
  final SosAlertStatus status;
  final double? latitude;
  final double? longitude;
  final String? note;

  /// `userId` of whoever resolved it — the alert's own owner ("I'm safe
  /// now") or an admin. Null until resolved.
  final String? resolvedBy;
  final DateTime? resolvedAt;

  bool get hasLocation => latitude != null && longitude != null;

  SosAlert copyWith({
    String? id,
    String? userId,
    DateTime? triggeredAt,
    SosAlertStatus? status,
    double? latitude,
    double? longitude,
    String? note,
    String? resolvedBy,
    DateTime? resolvedAt,
  }) {
    return SosAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      note: note ?? this.note,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SosAlert &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          triggeredAt == other.triggeredAt &&
          status == other.status &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          note == other.note &&
          resolvedBy == other.resolvedBy &&
          resolvedAt == other.resolvedAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        triggeredAt,
        status,
        latitude,
        longitude,
        note,
        resolvedBy,
        resolvedAt,
      );
}
