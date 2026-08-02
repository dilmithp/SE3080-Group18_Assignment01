import 'package:elderly_companion/features/scheduling/domain/entities/session_status.dart';

/// Pure domain entity — zero `package:firebase_*` imports. Data-layer DTOs
/// (see data/models/session_dto.dart) convert Firestore documents to and
/// from this type; nothing outside data/ should know Firestore exists.
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
  });

  final String id;
  final String requesterId;
  final String volunteerId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final SessionStatus status;
  final String location;
  final String? notes;

  Session copyWith({
    String? id,
    String? requesterId,
    String? volunteerId,
    DateTime? scheduledAt,
    int? durationMinutes,
    SessionStatus? status,
    String? location,
    String? notes,
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
          notes == other.notes;

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
      );
}
