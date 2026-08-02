/// Pure domain entity — zero `package:firebase_*` imports. Data-layer DTOs
/// (see data/models/session_feedback_dto.dart) convert Firestore documents
/// to and from this type; nothing outside data/ should know Firestore
/// exists.
class SessionFeedback {
  const SessionFeedback({
    required this.sessionId,
    required this.raterId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final String sessionId;
  final String raterId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  SessionFeedback copyWith({
    String? sessionId,
    String? raterId,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return SessionFeedback(
      sessionId: sessionId ?? this.sessionId,
      raterId: raterId ?? this.raterId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionFeedback &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          raterId == other.raterId &&
          rating == other.rating &&
          comment == other.comment &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(sessionId, raterId, rating, comment, createdAt);
}
