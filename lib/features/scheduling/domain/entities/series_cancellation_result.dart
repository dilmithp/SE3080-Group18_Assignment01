import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';

/// What came back from cancelling the remaining occurrences of a series.
///
/// Each occurrence is its own document and its own write, so a run can
/// succeed in part — the same shape, and the same honesty, as
/// [RecurringBookingResult]: what was cancelled is listed, and what failed
/// is named rather than rounded away.
class SeriesCancellationResult {
  const SeriesCancellationResult({
    required this.seriesId,
    required this.cancelledSessions,
    required this.failedSessionIds,
  });

  final String seriesId;

  /// Occurrences now cancelled, earliest first.
  final List<Session> cancelledSessions;

  /// Ids of occurrences whose cancellation failed. Empty on a clean run.
  final List<String> failedSessionIds;

  /// Whether every occurrence that was attempted is now cancelled.
  bool get isComplete => failedSessionIds.isEmpty;

  /// How many occurrences were attempted.
  int get attemptedCount => cancelledSessions.length + failedSessionIds.length;

  /// True when the series held nothing still cancellable — every occurrence
  /// had already finished or been called off. Not a failure: there was
  /// simply nothing to do.
  bool get nothingToCancel => attemptedCount == 0;

  @override
  String toString() => 'SeriesCancellationResult(seriesId: $seriesId, '
      'cancelled: ${cancelledSessions.length}, '
      'failed: ${failedSessionIds.length})';
}
