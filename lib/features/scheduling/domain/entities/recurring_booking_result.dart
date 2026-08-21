import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';

/// What came back from booking a recurring series.
///
/// A series is written one occurrence at a time, so a run can succeed in
/// part: [sessions] holds what was actually booked and [skippedOccurrences]
/// the dates whose write failed. Callers that need all-or-nothing must say
/// so — the use case does not roll back, because a Firestore batch cannot
/// span the conflict-checked first write and the plain ones after it.
class RecurringBookingResult {
  const RecurringBookingResult({
    required this.seriesId,
    required this.sessions,
    required this.skippedOccurrences,
  });

  /// Shared by every session in [sessions]; also written to each document,
  /// so the series can be found again later.
  final String seriesId;

  /// Successfully booked occurrences, earliest first. Never empty — a
  /// failure on the first occurrence is reported as a `Left(Failure)`
  /// instead of an empty result.
  final List<Session> sessions;

  /// Occurrence dates that could not be written. Empty on a clean run.
  final List<DateTime> skippedOccurrences;

  /// Whether every requested occurrence was booked.
  bool get isComplete => skippedOccurrences.isEmpty;

  /// How many occurrences were attempted.
  int get requestedCount => sessions.length + skippedOccurrences.length;

  @override
  String toString() => 'RecurringBookingResult(seriesId: $seriesId, '
      'booked: ${sessions.length}, skipped: ${skippedOccurrences.length})';
}
