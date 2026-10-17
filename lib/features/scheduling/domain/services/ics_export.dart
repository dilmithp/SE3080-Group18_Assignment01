import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';

/// Builds an iCalendar (.ics, RFC 5545) document for a user's upcoming
/// visits so they can be added to a phone or computer calendar.
///
/// Only requested and confirmed sessions are included. Notes are left out on
/// purpose: they are personal and not needed to show a calendar entry.
/// Pure Dart, no Firebase or Flutter imports.
String buildIcsCalendar(List<Session> sessions, {required DateTime generatedAt}) {
  final upcoming = sessions.where(
    (s) => s.status == SessionStatus.requested || s.status == SessionStatus.confirmed,
  );

  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//CareConnect//Visits//EN',
    'CALSCALE:GREGORIAN',
  ];

  for (final session in upcoming) {
    final start = session.scheduledAt.toUtc();
    final end = start.add(Duration(minutes: session.durationMinutes));
    lines.addAll([
      'BEGIN:VEVENT',
      'UID:${session.id}@careconnect',
      'DTSTAMP:${_utcStamp(generatedAt)}',
      'DTSTART:${_utcStamp(start)}',
      'DTEND:${_utcStamp(end)}',
      'SUMMARY:CareConnect visit (${_escape(session.status.label)})',
      'LOCATION:${_escape(session.location)}',
      'END:VEVENT',
    ]);
  }

  lines.add('END:VCALENDAR');
  return '${lines.join('\r\n')}\r\n';
}

String _utcStamp(DateTime value) {
  final utc = value.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}${two(utc.month)}${two(utc.day)}T'
      '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
}

/// RFC 5545 text escaping for values such as LOCATION and SUMMARY.
String _escape(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\r\n', r'\n')
      .replaceAll('\n', r'\n');
}
