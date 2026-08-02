import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/auth_trust/domain/entities/trust_score.dart';

part 'trust_score_dto.freezed.dart';
part 'trust_score_dto.g.dart';

@freezed
class TrustScoreDto with _$TrustScoreDto {
  const TrustScoreDto._();

  const factory TrustScoreDto({
    required String userId,
    required double score,
    required int completedSessions,
    required double averageRating,
    required int lastUpdatedMillis,
  }) = _TrustScoreDto;

  factory TrustScoreDto.fromJson(Map<String, dynamic> json) =>
      _$TrustScoreDtoFromJson(json);

  factory TrustScoreDto.fromEntity(TrustScore entity) => TrustScoreDto(
        userId: entity.userId,
        score: entity.score,
        completedSessions: entity.completedSessions,
        averageRating: entity.averageRating,
        lastUpdatedMillis: entity.lastUpdated.millisecondsSinceEpoch,
      );

  TrustScore toEntity() => TrustScore(
        userId: userId,
        score: score,
        completedSessions: completedSessions,
        averageRating: averageRating,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis),
      );
}
