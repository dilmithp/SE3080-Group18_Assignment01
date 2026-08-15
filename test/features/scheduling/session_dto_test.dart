import 'package:elderly_companion/features/scheduling/data/models/session_dto.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the entity <-> DTO boundary, and specifically that a session
/// stored before the lifecycle fields existed still reads back as a valid
/// [Session] instead of blowing up on a missing key.
void main() {
  final fullSession = Session(
    id: 'session-1',
    requesterId: 'elder-1',
    volunteerId: 'volunteer-1',
    scheduledAt: DateTime(2026, 9, 1, 10, 0),
    durationMinutes: 60,
    status: SessionStatus.confirmed,
    location: 'Community centre',
    notes: 'Ring the doorbell twice',
    isRecurring: true,
    recurrenceRule: 'FREQ=WEEKLY;BYDAY=TU',
    checkInAt: DateTime(2026, 9, 1, 10, 3),
    checkOutAt: DateTime(2026, 9, 1, 11, 1),
    conflictFlag: true,
    createdAt: DateTime(2026, 8, 25, 9, 0),
    updatedAt: DateTime(2026, 8, 26, 9, 0),
  );

  group('SessionDto <-> Session', () {
    test('round-trips every field, lifecycle fields included', () {
      expect(SessionDto.fromEntity(fullSession).toEntity(), fullSession);
    });

    test('round-trips a one-off session with no lifecycle data set', () {
      final minimal = Session(
        id: 'session-2',
        requesterId: 'elder-1',
        volunteerId: 'volunteer-1',
        scheduledAt: DateTime(2026, 9, 1, 10, 0),
        durationMinutes: 45,
        status: SessionStatus.requested,
        location: 'Library',
      );

      final entity = SessionDto.fromEntity(minimal).toEntity();

      expect(entity, minimal);
      expect(entity.isRecurring, isFalse);
      expect(entity.conflictFlag, isFalse);
      expect(entity.checkInAt, isNull);
      expect(entity.createdAt, isNull);
    });

    test('survives a JSON payload written before the lifecycle fields '
        'existed', () {
      final legacy = <String, dynamic>{
        'id': 'session-3',
        'requesterId': 'elder-1',
        'volunteerId': 'volunteer-1',
        'scheduledAtMillis': DateTime(2026, 9, 1, 10, 0).millisecondsSinceEpoch,
        'durationMinutes': 60,
        'status': 'requested',
        'location': 'Community centre',
      };

      final entity = SessionDto.fromJson(legacy).toEntity();

      expect(entity.id, 'session-3');
      expect(entity.status, SessionStatus.requested);
      expect(entity.isRecurring, isFalse);
      expect(entity.recurrenceRule, isNull);
      expect(entity.conflictFlag, isFalse);
      expect(entity.checkInAt, isNull);
      expect(entity.checkOutAt, isNull);
      expect(entity.createdAt, isNull);
      expect(entity.updatedAt, isNull);
    });

    test('serialises the lifecycle fields as epoch millis, not DateTime', () {
      final json = SessionDto.fromEntity(fullSession).toJson();

      expect(json['isRecurring'], isTrue);
      expect(json['recurrenceRule'], 'FREQ=WEEKLY;BYDAY=TU');
      expect(json['conflictFlag'], isTrue);
      expect(json['checkInAtMillis'], fullSession.checkInAt!.millisecondsSinceEpoch);
      expect(json['checkOutAtMillis'], fullSession.checkOutAt!.millisecondsSinceEpoch);
      expect(json['createdAtMillis'], fullSession.createdAt!.millisecondsSinceEpoch);
      expect(json['updatedAtMillis'], fullSession.updatedAt!.millisecondsSinceEpoch);
    });

    test('json round-trip is lossless', () {
      final dto = SessionDto.fromEntity(fullSession);

      expect(SessionDto.fromJson(dto.toJson()), dto);
    });
  });
}
