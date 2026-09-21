import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/sos/domain/entities/sos_alert.dart';
import 'package:elderly_companion/features/sos/domain/entities/sos_alert_status.dart';

part 'sos_alert_dto.freezed.dart';
part 'sos_alert_dto.g.dart';

/// Firestore-shaped DTO for the `sos_alerts` collection. Converts to/from
/// the pure [SosAlert] domain entity. Dates are stored as epoch
/// milliseconds, matching every other DTO in this project.
@freezed
abstract class SosAlertDto with _$SosAlertDto {
  const SosAlertDto._();

  const factory SosAlertDto({
    required String id,
    required String userId,
    required int triggeredAtMillis,
    required String status,
    double? latitude,
    double? longitude,
    String? note,
    String? resolvedBy,
    int? resolvedAtMillis,
  }) = _SosAlertDto;

  factory SosAlertDto.fromJson(Map<String, dynamic> json) =>
      _$SosAlertDtoFromJson(json);

  factory SosAlertDto.fromEntity(SosAlert entity) => SosAlertDto(
        id: entity.id,
        userId: entity.userId,
        triggeredAtMillis: entity.triggeredAt.millisecondsSinceEpoch,
        status: entity.status.value,
        latitude: entity.latitude,
        longitude: entity.longitude,
        note: entity.note,
        resolvedBy: entity.resolvedBy,
        resolvedAtMillis: entity.resolvedAt?.millisecondsSinceEpoch,
      );

  SosAlert toEntity() => SosAlert(
        id: id,
        userId: userId,
        triggeredAt: DateTime.fromMillisecondsSinceEpoch(triggeredAtMillis),
        status: SosAlertStatus.fromValue(status),
        latitude: latitude,
        longitude: longitude,
        note: note,
        resolvedBy: resolvedBy,
        resolvedAt: resolvedAtMillis == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(resolvedAtMillis!),
      );
}
