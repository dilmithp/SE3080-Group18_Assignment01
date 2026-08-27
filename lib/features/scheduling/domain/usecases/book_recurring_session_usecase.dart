import 'dart:math';

import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/recurrence_rule.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/recurring_booking_result.dart';
import 'package:elderly_companion/features/scheduling/domain/entities/session.dart';
import 'package:elderly_companion/features/scheduling/domain/repositories/session_repository.dart';

/// Single business rule: book a repeating arrangement as a series of
/// individual sessions sharing one `seriesId`.
///
/// Occurrence dates come from [RecurrenceRule.nextOccurrences], anchored on
/// the requested start; each one is written through the same
/// [SessionRepository.bookSession] path a one-off booking uses, so a series
/// occurrence is an ordinary session that happens to carry recurrence
/// metadata. Nothing here expands the rule lazily or stores a series
/// document of its own.
///
/// ## Known limitations
///
/// **Only the first occurrence gates the run.** If booking it fails, the
/// call returns `Left` and writes nothing else. Later occurrences are
/// written regardless of what is already in the calendar — nothing checks
/// them for clashes, so a series can be laid down across a slot that is
/// already taken. Note also what "conflict-checked" means today: the
/// booking path itself does *not* check overlaps, because a `requested`
/// session holds no slot — the real check happens at accept time in
/// `confirmSession`. So the first occurrence is gated only on the write
/// succeeding, not on the slot being free.
/// TODO(ranketh): re-check each occurrence — and ideally write the series
/// in one batch — once conflict checking can see both participants'
/// calendars (that needs the Admin SDK, i.e. the backend/ Cloud Function).
///
/// **The occurrence count is a placeholder.** [defaultOccurrenceCount] is a
/// working default so a series is bounded, not a product decision. Nobody
/// has chosen how far ahead a recurring booking should reach, and the rule
/// format has no `UNTIL`/`COUNT` of its own yet.
/// TODO(ranketh): let the person booking choose the horizon, or give the
/// rule format an end date, once the UI for recurring bookings is designed.
///
/// A partly-written series is reported, not hidden: see
/// [RecurringBookingResult.skippedOccurrences].
class BookRecurringSessionUseCase {
  BookRecurringSessionUseCase(
    this._repository, {
    String Function()? seriesIdGenerator,
  }) : _seriesIdGenerator = seriesIdGenerator ?? _generateSeriesId;

  /// How many occurrences a series covers when the caller does not say.
  /// Placeholder — see the class doc.
  static const int defaultOccurrenceCount = 8;

  final SessionRepository _repository;
  final String Function() _seriesIdGenerator;

  /// Books [occurrenceCount] occurrences of [recurrence], the first at
  /// [scheduledAt].
  ///
  /// [scheduledAt] is the anchor as well as the first occurrence: it fixes
  /// the time of day, and for a weekly rule with no `BYDAY`, the weekday.
  /// If it does not itself match the rule, the series starts at the first
  /// date that does.
  Future<Either<Failure, RecurringBookingResult>> call({
    required String requesterId,
    required String volunteerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String location,
    required RecurrenceRule recurrence,
    String? notes,
    int occurrenceCount = defaultOccurrenceCount,
  }) async {
    if (occurrenceCount < 1) {
      return const Left(
        UnknownFailure('A recurring booking needs at least one session.'),
      );
    }

    final occurrences = recurrence.nextOccurrences(
      from: scheduledAt,
      count: occurrenceCount,
    );
    if (occurrences.isEmpty) {
      return const Left(
        UnknownFailure('This repeat pattern produced no sessions.'),
      );
    }

    final seriesId = _seriesIdGenerator();
    final ruleString = recurrence.toRuleString();

    Future<Either<Failure, Session>> book(DateTime at) =>
        _repository.bookSession(
          requesterId: requesterId,
          volunteerId: volunteerId,
          scheduledAt: at,
          durationMinutes: durationMinutes,
          location: location,
          notes: notes,
          isRecurring: true,
          recurrenceRule: ruleString,
          seriesId: seriesId,
        );

    // The first occurrence gates the run: if it cannot be booked, nothing
    // else is written, so a failed attempt leaves no half-series behind.
    final first = await book(occurrences.first);
    final failure = first.fold<Failure?>((failure) => failure, (_) => null);
    if (failure != null) return Left(failure);

    final sessions = <Session>[];
    final skipped = <DateTime>[];
    first.fold((_) {}, sessions.add);

    // Written in order, one at a time: each occurrence is its own document,
    // and a failure part-way through leaves the earlier ones in place
    // rather than unwinding them.
    for (final occurrence in occurrences.skip(1)) {
      final booked = await book(occurrence);
      booked.fold((_) => skipped.add(occurrence), sessions.add);
    }

    return Right(
      RecurringBookingResult(
        seriesId: seriesId,
        sessions: sessions,
        skippedOccurrences: skipped,
      ),
    );
  }

  /// Series ids are generated here rather than by Firestore: the id has to
  /// be known before the first write so every occurrence can carry it, and
  /// the domain layer must not reach for a document reference to get one.
  /// Timestamp plus randomness is enough — this identifies a series within
  /// one user's calendar, it is not a security token.
  static String _generateSeriesId() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final suffix = List.generate(
      8,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    return 'series-${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }
}
