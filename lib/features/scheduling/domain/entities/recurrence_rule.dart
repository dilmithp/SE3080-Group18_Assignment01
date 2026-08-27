/// How often a repeating session recurs.
enum RecurrenceFrequency {
  daily('DAILY'),
  weekly('WEEKLY');

  const RecurrenceFrequency(this.code);

  /// The token used in a rule string.
  final String code;
}

/// A day of the week, as a two-letter rule-string code.
enum RecurrenceDay {
  monday('MO', DateTime.monday, 'Monday'),
  tuesday('TU', DateTime.tuesday, 'Tuesday'),
  wednesday('WE', DateTime.wednesday, 'Wednesday'),
  thursday('TH', DateTime.thursday, 'Thursday'),
  friday('FR', DateTime.friday, 'Friday'),
  saturday('SA', DateTime.saturday, 'Saturday'),
  sunday('SU', DateTime.sunday, 'Sunday');

  const RecurrenceDay(this.code, this.weekday, this.label);

  /// The token used in a rule string, e.g. `MO`.
  final String code;

  /// The matching `DateTime.weekday` value, so callers never hand-map these.
  final int weekday;

  /// Human-readable day name, for the same reason [SessionStatus] carries
  /// its own label: the display string belongs with the value, not copied
  /// into every widget that renders it.
  final String label;

  /// The first three letters, for a chip or other tight space.
  String get shortLabel => label.substring(0, 3);

  static RecurrenceDay? fromCode(String code) {
    for (final day in RecurrenceDay.values) {
      if (day.code == code) return day;
    }
    return null;
  }

  static RecurrenceDay fromWeekday(int weekday) =>
      RecurrenceDay.values.firstWhere((day) => day.weekday == weekday);
}

/// A parsed `Session.recurrenceRule`.
///
/// ## Format
///
/// A deliberately small RRULE-inspired subset — semicolon-separated
/// `KEY=VALUE` parts, in any order:
///
/// * `FREQ=WEEKLY` or `FREQ=DAILY` — **required**.
/// * `INTERVAL=n` — optional, a positive integer, defaults to `1`. "Every
///   other week" is `FREQ=WEEKLY;INTERVAL=2`.
/// * `BYDAY=MO,WE` — optional list of `MO TU WE TH FR SA SU`. Only valid
///   with `FREQ=WEEKLY`; a weekly rule without it repeats on whatever
///   weekday the series is anchored to.
///
/// `FREQ=WEEKLY;BYDAY=TU` and `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE` are both
/// valid. Anything else — an unknown key, a bad day code, `INTERVAL=0`, a
/// `BYDAY` on a daily rule — is treated as unparseable rather than
/// partially honoured: this field is free text on a document that a buggy
/// write or an older client could have corrupted, and half-obeying a
/// corrupt schedule is worse than ignoring it.
///
/// ## Deliberate omissions
///
/// No `UNTIL`, `COUNT`, `BYMONTHDAY`, or monthly/yearly frequency. Callers
/// ask for a bounded number of occurrences via [nextOccurrences], so a rule
/// needs no end date of its own yet. Adding a key later is additive — old
/// strings stay valid.
///
/// Pure Dart: no Firestore, no [Session], no UI. Parsing never throws.
///
/// Owner: Ranketh (features/scheduling).
class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.days = const {},
  });

  final RecurrenceFrequency frequency;

  /// How many periods between occurrences — `2` with [RecurrenceFrequency.weekly]
  /// means fortnightly. Always >= 1 for an instance built by [tryParse].
  final int interval;

  /// The weekdays a weekly rule falls on. Empty means "the same weekday the
  /// series is anchored to", resolved in [nextOccurrences] from its `from`
  /// argument. Always empty for a daily rule.
  final Set<RecurrenceDay> days;

  /// Parses [rule], returning `null` for anything malformed — including
  /// `null` or blank input, so callers can pass a raw field straight
  /// through. Keys are matched case-insensitively.
  static RecurrenceRule? tryParse(String? rule) {
    if (rule == null) return null;
    final trimmed = rule.trim();
    if (trimmed.isEmpty) return null;

    RecurrenceFrequency? frequency;
    int? interval;
    Set<RecurrenceDay>? days;

    for (final part in trimmed.toUpperCase().split(';')) {
      final token = part.trim();
      if (token.isEmpty) return null;

      final separator = token.indexOf('=');
      if (separator <= 0 || separator == token.length - 1) return null;
      final key = token.substring(0, separator).trim();
      final value = token.substring(separator + 1).trim();

      switch (key) {
        case 'FREQ':
          // A repeated key is a corrupt string, not a last-one-wins merge.
          if (frequency != null) return null;
          frequency = _frequencyFromCode(value);
          if (frequency == null) return null;
        case 'INTERVAL':
          if (interval != null) return null;
          final parsed = int.tryParse(value);
          if (parsed == null || parsed < 1) return null;
          interval = parsed;
        case 'BYDAY':
          if (days != null) return null;
          final parsedDays = _daysFromCodes(value);
          if (parsedDays == null) return null;
          days = parsedDays;
        default:
          // Unknown key: refuse the whole rule rather than silently
          // dropping a constraint that might have narrowed the schedule.
          return null;
      }
    }

    if (frequency == null) return null;
    // BYDAY has no meaning for a daily rule, and guessing which of the two
    // the writer meant is not this parser's job.
    if (frequency == RecurrenceFrequency.daily &&
        days != null &&
        days.isNotEmpty) {
      return null;
    }

    return RecurrenceRule(
      frequency: frequency,
      interval: interval ?? 1,
      days: days ?? const {},
    );
  }

  /// The next [count] occurrences at or after [from], in chronological
  /// order. Returns an empty list for a non-positive [count].
  ///
  /// [from] is the anchor as well as the lower bound: it supplies the
  /// time of day for every occurrence, the weekday for a weekly rule with
  /// no [days], and the week an [interval] counts from. An occurrence
  /// falling exactly on [from] is included.
  ///
  /// Dates are built with calendar arithmetic rather than by adding
  /// [Duration]s, so a series crossing a daylight-saving boundary keeps its
  /// wall-clock time instead of drifting by an hour. A UTC [from] yields
  /// UTC occurrences.
  List<DateTime> nextOccurrences({
    required DateTime from,
    required int count,
  }) {
    if (count <= 0) return const [];

    switch (frequency) {
      case RecurrenceFrequency.daily:
        return [
          for (var i = 0; i < count; i++) _shiftDays(from, i * interval),
        ];

      case RecurrenceFrequency.weekly:
        final weekdays = (days.isEmpty
            ? <int>[from.weekday]
            : days.map((day) => day.weekday).toList())
          ..sort();

        final occurrences = <DateTime>[];
        // Monday of the anchor week; `interval` then steps whole weeks from
        // there, so the day-of-week pattern never slides.
        var weekStart = _shiftDays(from, DateTime.monday - from.weekday);

        while (occurrences.length < count) {
          for (final weekday in weekdays) {
            final occurrence =
                _shiftDays(weekStart, weekday - DateTime.monday);
            // Days earlier in the anchor week are in the past for this
            // request; later weeks can never trip this.
            if (occurrence.isBefore(from)) continue;
            occurrences.add(occurrence);
            if (occurrences.length == count) break;
          }
          weekStart = _shiftDays(weekStart, 7 * interval);
        }
        return occurrences;
    }
  }

  /// The canonical rule string for this value: `INTERVAL` is omitted when
  /// it is 1 and `BYDAY` when [days] is empty, so a round-trip through
  /// [tryParse] is stable.
  String toRuleString() {
    final parts = <String>['FREQ=${frequency.code}'];
    if (interval != 1) parts.add('INTERVAL=$interval');
    if (days.isNotEmpty) {
      final ordered = days.toList()
        ..sort((a, b) => a.weekday.compareTo(b.weekday));
      parts.add('BYDAY=${ordered.map((day) => day.code).join(',')}');
    }
    return parts.join(';');
  }

  static RecurrenceFrequency? _frequencyFromCode(String code) {
    for (final frequency in RecurrenceFrequency.values) {
      if (frequency.code == code) return frequency;
    }
    return null;
  }

  /// `MO,WE` -> the matching days, or `null` if any code is unknown or the
  /// list is empty.
  static Set<RecurrenceDay>? _daysFromCodes(String value) {
    final codes = value.split(',');
    final days = <RecurrenceDay>{};
    for (final code in codes) {
      final day = RecurrenceDay.fromCode(code.trim());
      if (day == null) return null;
      days.add(day);
    }
    return days.isEmpty ? null : days;
  }

  /// Calendar-day arithmetic that preserves time of day and UTC-ness.
  /// `DateTime(y, m, d + n)` normalises month and year overflow itself.
  static DateTime _shiftDays(DateTime base, int days) {
    if (base.isUtc) {
      return DateTime.utc(
        base.year,
        base.month,
        base.day + days,
        base.hour,
        base.minute,
        base.second,
        base.millisecond,
        base.microsecond,
      );
    }
    return DateTime(
      base.year,
      base.month,
      base.day + days,
      base.hour,
      base.minute,
      base.second,
      base.millisecond,
      base.microsecond,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceRule &&
          runtimeType == other.runtimeType &&
          frequency == other.frequency &&
          interval == other.interval &&
          days.length == other.days.length &&
          days.containsAll(other.days);

  @override
  int get hashCode => Object.hash(
        frequency,
        interval,
        // Order-independent, to match the set semantics in ==.
        Object.hashAllUnordered(days),
      );

  @override
  String toString() => 'RecurrenceRule(${toRuleString()})';
}
