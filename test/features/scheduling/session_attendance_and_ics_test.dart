import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/services/ics_export.dart';
import 'package:elderly_companion/features/scheduling/domain/services/session_attendance_rules.dart';
import 'package:flutter_test/flutter_test.dart';

final _visit = DateTime.utc(2026, 10, 10, 9, 0);

Session _session({
  SessionStatus status = SessionStatus.confirmed,
  DateTime? checkInAt,
  DateTime? checkOutAt,
  String location = 'Colombo 07 library',
  String id = 's1',
}) {
  return Session(
    id: id,
    requesterId: 'elderly-1',
    volunteerId: 'volunteer-1',
    scheduledAt: _visit,
    durationMinutes: 60,
    status: status,
    location: location,
    checkInAt: checkInAt,
    checkOutAt: checkOutAt,
  );
}

void main() {
  group('SessionAttendanceRules.canCheckIn', () {
    test('opens 30 minutes before the visit', () {
      final s = _session();

      expect(SessionAttendanceRules.canCheckIn(s, _visit.subtract(const Duration(minutes: 31))), isFalse);
      expect(SessionAttendanceRules.canCheckIn(s, _visit.subtract(const Duration(minutes: 30))), isTrue);
    });

    test('closes when the visit is due to end', () {
      final s = _session();

      expect(SessionAttendanceRules.canCheckIn(s, _visit.add(const Duration(minutes: 59))), isTrue);
      expect(SessionAttendanceRules.canCheckIn(s, _visit.add(const Duration(minutes: 60))), isFalse);
    });

    test('is refused for a session that is not confirmed', () {
      final requested = _session(status: SessionStatus.requested);

      expect(SessionAttendanceRules.canCheckIn(requested, _visit), isFalse);
    });

    test('is refused once already checked in', () {
      final s = _session(checkInAt: _visit);

      expect(SessionAttendanceRules.canCheckIn(s, _visit), isFalse);
    });
  });

  group('SessionAttendanceRules.canCheckOut', () {
    test('is only possible after check-in', () {
      expect(SessionAttendanceRules.canCheckOut(_session()), isFalse);
      expect(SessionAttendanceRules.canCheckOut(_session(checkInAt: _visit)), isTrue);
    });

    test('is refused once checked out', () {
      final s = _session(checkInAt: _visit, checkOutAt: _visit);

      expect(SessionAttendanceRules.canCheckOut(s), isFalse);
    });
  });

  group('buildIcsCalendar', () {
    final generated = DateTime.utc(2026, 10, 3, 6, 0);

    test('wraps the events in a VCALENDAR with CRLF line endings', () {
      final ics = buildIcsCalendar([_session()], generatedAt: generated);

      expect(ics, startsWith('BEGIN:VCALENDAR\r\n'));
      expect(ics, endsWith('END:VCALENDAR\r\n'));
      expect(ics, contains('BEGIN:VEVENT'));
    });

    test('writes start and end in UTC', () {
      final ics = buildIcsCalendar([_session()], generatedAt: generated);

      expect(ics, contains('DTSTART:20261010T090000Z'));
      expect(ics, contains('DTEND:20261010T100000Z'));
    });

    test('escapes commas and semicolons in the location', () {
      final ics = buildIcsCalendar(
        [_session(location: 'Flat 4, Block B; front door')],
        generatedAt: generated,
      );

      expect(ics, contains(r'LOCATION:Flat 4\, Block B\; front door'));
    });

    test('leaves out cancelled and completed sessions', () {
      final ics = buildIcsCalendar(
        [
          _session(id: 'a', status: SessionStatus.cancelled),
          _session(id: 'b', status: SessionStatus.completed),
          _session(id: 'c'),
        ],
        generatedAt: generated,
      );

      expect(ics, isNot(contains('UID:a@careconnect')));
      expect(ics, isNot(contains('UID:b@careconnect')));
      expect(ics, contains('UID:c@careconnect'));
    });

    test('no sessions gives an empty calendar', () {
      final ics = buildIcsCalendar(const [], generatedAt: generated);

      expect(ics, isNot(contains('BEGIN:VEVENT')));
      expect(ics, contains('END:VCALENDAR'));
    });
  });
}
