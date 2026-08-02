import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/scheduling/domain/entities/session_feedback.dart';

part 'session_feedback_dto.freezed.dart';
part 'session_feedback_dto.g.dart';

/// Firestore-shaped DTO for the `session_feedback` collection. Converts
/// to/from the pure [SessionFeedback] domain entity — see [toEntity] /
/// [SessionFeedbackDto.fromEntity]. Dates are stored as epoch milliseconds
/// so this class stays plain-JSON (no custom `Timestamp` converter
/// needed); the data source is responsible for bridging Firestore's
/// `Timestamp` type at the boundary.
@freezed
class SessionFeedbackDto with _$SessionFeedbackDto {
  const SessionFeedbackDto._();

  const factory SessionFeedbackDto({
    required String sessionId,
    required String raterId,
    required int rating,
    required int createdAtMillis,
    String? comment,
  }) = _SessionFeedbackDto;

  factory SessionFeedbackDto.fromJson(Map<String, dynamic> json) =>
      _$SessionFeedbackDtoFromJson(json);

  factory SessionFeedbackDto.fromEntity(SessionFeedback entity) =>
      SessionFeedbackDto(
        sessionId: entity.sessionId,
        raterId: entity.raterId,
        rating: entity.rating,
        comment: entity.comment,
        createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      );

  SessionFeedback toEntity() => SessionFeedback(
        sessionId: sessionId,
        raterId: raterId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      );
}
