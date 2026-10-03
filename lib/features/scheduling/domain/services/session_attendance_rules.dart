import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';

/// When a participant may check in and out of a visit. Pure Dart, so the
/// rules can be unit tested without a clock or Firestore.
///
/// Check-in opens 30 minutes before the visit and closes when it is due to
/// end. Check-out is only possible after check-in. Only confirmed sessions
/// can be attended.
class SessionAttendanceRules {
  const SessionAttendanceRules._();

  static const Duration checkInOpensBefore = Duration(minutes: 30);

  static bool canCheckIn(Session session, DateTime now) {
    if (session.status != SessionStatus.confirmed) return false;
    if (session.checkInAt != null) return false;
    final opensAt = session.scheduledAt.subtract(checkInOpensBefore);
    final endsAt = session.scheduledAt.add(Duration(minutes: session.durationMinutes));
    return !now.isBefore(opensAt) && now.isBefore(endsAt);
  }

  static bool canCheckOut(Session session) {
    return session.status == SessionStatus.confirmed &&
        session.checkInAt != null &&
        session.checkOutAt == null;
  }
}
