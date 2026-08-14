import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';

/// Pure domain entity — zero `package:firebase_*` imports. Data-layer DTOs
/// (see data/models/session_dto.dart) convert Firestore documents to and
/// from this type; nothing outside data/ should know Firestore exists.
///
/// The lifecycle fields below ([isRecurring] through [updatedAt]) are
/// nullable or defaulted throughout: sessions written before they existed
/// have no such keys, and a session read back from one of those documents
/// must still be a valid [Session] rather than a parse failure.
class Session {
  const Session({
    required this.id,
    required this.requesterId,
    required this.volunteerId,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    required this.location,
    this.notes,
    this.isRecurring = false,
    this.recurrenceRule,
    this.checkInAt,
    this.checkOutAt,
    this.conflictFlag = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String requesterId;
  final String volunteerId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final SessionStatus status;
  final String location;
  final String? notes;

  /// Whether this session is one occurrence of a repeating arrangement.
  /// Kept alongside [recurrenceRule] rather than derived from it so a
  /// one-off booking is unambiguous even before the rule is parsed.
  final bool isRecurring;

  /// How the series repeats, when [isRecurring]. Held as an opaque string
  /// here — the domain does not expand it yet; that is the recurring
  /// sessions chunk.
  final String? recurrenceRule;

  /// When the session actually started, as recorded by a participant.
  /// `null` until someone checks in — which is also how "did this session
  /// really happen" is answered later.
  final DateTime? checkInAt;

  /// When the session actually ended. `null` until someone checks out.
  final DateTime? checkOutAt;

  /// Set when this session was accepted despite overlapping another
  /// booking — a booking the conflict check could not see, e.g. on the
  /// counterparty's side of the calendar. Purely advisory: it flags a
  /// session for a human to look at, it does not block anything.
  final bool conflictFlag;

  /// Audit timestamps. Nullable because documents written before these
  /// fields existed carry neither.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Note the repo-wide caveat: a `??` copyWith cannot null a field back
  /// out, so clearing [checkInAt] etc. means constructing a [Session]
  /// directly. Same limitation [notes] has always had — kept deliberately
  /// consistent rather than introducing a sentinel just for these fields.
  Session copyWith({
    String? id,
    String? requesterId,
    String? volunteerId,
    DateTime? scheduledAt,
    int? durationMinutes,
    SessionStatus? status,
    String? location,
    String? notes,
    bool? isRecurring,
    String? recurrenceRule,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    bool? conflictFlag,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      volunteerId: volunteerId ?? this.volunteerId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      conflictFlag: conflictFlag ?? this.conflictFlag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          requesterId == other.requesterId &&
          volunteerId == other.volunteerId &&
          scheduledAt == other.scheduledAt &&
          durationMinutes == other.durationMinutes &&
          status == other.status &&
          location == other.location &&
          notes == other.notes &&
          isRecurring == other.isRecurring &&
          recurrenceRule == other.recurrenceRule &&
          checkInAt == other.checkInAt &&
          checkOutAt == other.checkOutAt &&
          conflictFlag == other.conflictFlag &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        requesterId,
        volunteerId,
        scheduledAt,
        durationMinutes,
        status,
        location,
        notes,
        isRecurring,
        recurrenceRule,
        checkInAt,
        checkOutAt,
        conflictFlag,
        createdAt,
        updatedAt,
      );
}
