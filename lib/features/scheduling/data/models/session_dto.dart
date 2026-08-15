import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';

part 'session_dto.freezed.dart';
part 'session_dto.g.dart';

/// Firestore-shaped DTO for the `sessions` collection. Converts to/from the
/// pure [Session] domain entity — see [toEntity] / [SessionDto.fromEntity].
/// Dates are stored as epoch milliseconds so this class stays plain-JSON
/// (no custom `Timestamp` converter needed); the data source is
/// responsible for bridging Firestore's `Timestamp` type at the boundary.
///
/// Every lifecycle field added after the first release is optional or
/// defaulted: documents written before those fields existed carry no such
/// keys, and reading one back must produce a valid DTO rather than a parse
/// failure.
@freezed
class SessionDto with _$SessionDto {
  const SessionDto._();

  const factory SessionDto({
    required String id,
    required String requesterId,
    required String volunteerId,
    required int scheduledAtMillis,
    required int durationMinutes,
    required String status,
    required String location,
    String? notes,
    @Default(false) bool isRecurring,
    String? recurrenceRule,
    int? checkInAtMillis,
    int? checkOutAtMillis,
    @Default(false) bool conflictFlag,
    int? createdAtMillis,
    int? updatedAtMillis,
  }) = _SessionDto;

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  factory SessionDto.fromEntity(Session entity) => SessionDto(
        id: entity.id,
        requesterId: entity.requesterId,
        volunteerId: entity.volunteerId,
        scheduledAtMillis: entity.scheduledAt.millisecondsSinceEpoch,
        durationMinutes: entity.durationMinutes,
        status: entity.status.name,
        location: entity.location,
        notes: entity.notes,
        isRecurring: entity.isRecurring,
        recurrenceRule: entity.recurrenceRule,
        checkInAtMillis: entity.checkInAt?.millisecondsSinceEpoch,
        checkOutAtMillis: entity.checkOutAt?.millisecondsSinceEpoch,
        conflictFlag: entity.conflictFlag,
        createdAtMillis: entity.createdAt?.millisecondsSinceEpoch,
        updatedAtMillis: entity.updatedAt?.millisecondsSinceEpoch,
      );

  Session toEntity() => Session(
        id: id,
        requesterId: requesterId,
        volunteerId: volunteerId,
        scheduledAt: DateTime.fromMillisecondsSinceEpoch(scheduledAtMillis),
        durationMinutes: durationMinutes,
        status: SessionStatus.values.byName(status),
        location: location,
        notes: notes,
        isRecurring: isRecurring,
        recurrenceRule: recurrenceRule,
        checkInAt: _dateOrNull(checkInAtMillis),
        checkOutAt: _dateOrNull(checkOutAtMillis),
        conflictFlag: conflictFlag,
        createdAt: _dateOrNull(createdAtMillis),
        updatedAt: _dateOrNull(updatedAtMillis),
      );

  static DateTime? _dateOrNull(int? millis) =>
      millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
}
