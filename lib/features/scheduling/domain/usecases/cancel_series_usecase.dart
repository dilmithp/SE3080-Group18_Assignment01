import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/series_cancellation_result.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';
import 'package:elderly_companion/features/scheduling/domain/services/session_series.dart';

/// Single business rule: call off the rest of a repeating series.
///
/// Only occurrences the lifecycle still allows to be cancelled are touched —
/// a session already completed stays completed, and one already cancelled is
/// not written again (see [SessionStatus.canTransitionTo]). Sessions are
/// passed in rather than fetched: the caller already holds the series from
/// the sessions-for-user stream, and cancelling exactly what was on screen
/// beats re-reading a possibly different list.
///
/// ## Known limitations
///
/// **No rollback.** Each occurrence is its own write, so a failure part-way
/// through leaves the earlier cancellations in place; the run continues and
/// reports what it managed, in [SeriesCancellationResult.failedSessionIds].
/// A batch would need every write to go through one code path — worth doing
/// if bulk cancelling becomes common.
///
/// **Cancelling a series does not stop it repeating.** There is no series
/// document to close, and nothing generates further occurrences on its own
/// today: a series is only ever the fixed set of sessions
/// [BookRecurringSessionUseCase] wrote. If occurrences are ever generated
/// rolling-forward, this needs to mark the series ended as well.
/// TODO(ranketh): revisit when/if series are extended beyond their initial
/// occurrence count.
class CancelSeriesUseCase {
  const CancelSeriesUseCase(
    this._repository, {
    SessionSeries series = const SessionSeries(),
  }) : _series = series;

  final SessionRepository _repository;
  final SessionSeries _series;

  /// Cancels every still-cancellable occurrence in [occurrences].
  ///
  /// Returns `Right` even when nothing was cancellable — see
  /// [SeriesCancellationResult.nothingToCancel]. A `Left` means the request
  /// itself made no sense, not that a write failed.
  Future<Either<Failure, SeriesCancellationResult>> call({
    required String seriesId,
    required Iterable<Session> occurrences,
  }) async {
    if (seriesId.isEmpty) {
      return const Left(UnknownFailure('This session is not part of a series.'));
    }

    final mine = occurrences.where((session) => session.seriesId == seriesId);
    final cancellable = _series.cancellableOccurrences(mine);

    final cancelled = <Session>[];
    final failed = <String>[];

    for (final occurrence in cancellable) {
      final result = await _repository.updateSessionStatus(
        sessionId: occurrence.id,
        status: SessionStatus.cancelled,
      );
      result.fold(
        (_) => failed.add(occurrence.id),
        cancelled.add,
      );
    }

    return Right(
      SeriesCancellationResult(
        seriesId: seriesId,
        cancelledSessions: cancelled,
        failedSessionIds: failed,
      ),
    );
  }
}
