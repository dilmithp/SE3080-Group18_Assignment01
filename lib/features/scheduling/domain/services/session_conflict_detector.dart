import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';

/// Decides whether a session would double-book somebody.
///
/// Pure Dart and side-effect free: it is handed the candidate plus whatever
/// sessions were read from Firestore and answers a question about them. It
/// never reads or writes anything itself, so the transaction that calls it
/// (see the `requested → confirmed` path) stays the only place that talks
/// to the database, and the rule itself is testable without Firebase.
///
/// Owner: Ranketh (features/scheduling).
class SessionConflictDetector {
  const SessionConflictDetector({
    this.blockingStatuses = const {SessionStatus.confirmed},
  });

  /// Statuses that actually hold a slot. Only `confirmed` does by default:
  /// an elder may have several pending `requested` sessions for the same
  /// hour from different volunteers — that is the normal shape of asking
  /// around, and only the one that gets accepted takes the slot. Pass a
  /// wider set to warn earlier (e.g. at request time).
  final Set<SessionStatus> blockingStatuses;

  /// Every session in [existing] that would clash with [candidate] — same
  /// person, overlapping time, slot-holding status.
  ///
  /// [candidate] is matched out of [existing] by id, so passing the stored
  /// copy of the session being confirmed does not make it conflict with
  /// itself.
  List<Session> conflictsFor({
    required Session candidate,
    required Iterable<Session> existing,
  }) {
    return existing
        .where((other) => other.id != candidate.id)
        .where((other) => blockingStatuses.contains(other.status))
        .where((other) => sharesParticipant(candidate, other))
        .where((other) => overlaps(candidate, other))
        .toList();
  }

  bool hasConflict({
    required Session candidate,
    required Iterable<Session> existing,
  }) {
    return conflictsFor(candidate: candidate, existing: existing).isNotEmpty;
  }

  /// Whether the two sessions share a requester or volunteer — in either
  /// role, since one person can be the requester on one session and the
  /// volunteer on another and still only be in one place at a time.
  bool sharesParticipant(Session a, Session b) {
    final participants = {a.requesterId, a.volunteerId};
    return participants.contains(b.requesterId) ||
        participants.contains(b.volunteerId);
  }

  /// Whether the two time ranges intersect.
  ///
  /// Intervals are half-open — `[start, end)` — so a session ending at 3:00
  /// and one starting at 3:00 do not conflict. A non-positive duration
  /// yields an empty interval that overlaps nothing, rather than silently
  /// clashing with every neighbouring session.
  bool overlaps(Session a, Session b) {
    if (a.durationMinutes <= 0 || b.durationMinutes <= 0) return false;
    return a.scheduledAt.isBefore(endOf(b)) && b.scheduledAt.isBefore(endOf(a));
  }

  /// The moment a session finishes — exclusive, per [overlaps].
  DateTime endOf(Session session) =>
      session.scheduledAt.add(Duration(minutes: session.durationMinutes));
}
