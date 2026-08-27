import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';

/// Reads a recurring series out of a list of sessions.
///
/// A series is not a document of its own — it is whatever occurrences carry
/// the same `seriesId` (see [BookRecurringSessionUseCase]). Since the
/// sessions-for-user stream already delivers every session a person is on,
/// finding a series is a filter over data the app has in hand rather than a
/// second Firestore query, which also keeps it out of reach of an index
/// nobody has created.
///
/// Pure Dart, like [SessionConflictDetector] and [FeedbackEligibility].
///
/// Owner: Ranketh (features/scheduling).
class SessionSeries {
  const SessionSeries();

  /// Every session belonging to [seriesId], earliest first.
  ///
  /// A blank [seriesId] matches nothing: `null` is what a one-off booking
  /// carries, and treating "no series" as a series would sweep up every
  /// standalone session in the list.
  List<Session> occurrencesOf({
    required String seriesId,
    required Iterable<Session> sessions,
  }) {
    if (seriesId.isEmpty) return const [];
    return sessions.where((session) => session.seriesId == seriesId).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// The occurrences of [sessions] that can still be called off — anything
  /// the lifecycle allows to move to [SessionStatus.cancelled], which
  /// excludes sessions already completed or cancelled.
  ///
  /// Takes a list of occurrences rather than a `seriesId` so the caller can
  /// pass what it already rendered, and what it cancels is exactly what the
  /// person was looking at.
  List<Session> cancellableOccurrences(Iterable<Session> sessions) {
    return sessions
        .where((session) => session.status.canTransitionTo(SessionStatus.cancelled))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Whether [sessions] holds anything still worth cancelling.
  bool hasCancellableOccurrences(Iterable<Session> sessions) =>
      sessions.any(
        (session) => session.status.canTransitionTo(SessionStatus.cancelled),
      );
}
