import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/matching/domain/entities/match_candidate.dart';
import 'package:elderly_companion/features/profiles/data/models/user_profile_dto.dart';

part 'match_candidate_dto.freezed.dart';
part 'match_candidate_dto.g.dart';

/// Firestore-shaped DTO for a ranked match result. Converts to/from the
/// pure [MatchCandidate] domain entity — see [toEntity] /
/// [MatchCandidateDto.fromEntity].
///
/// `profile` is stored as a raw JSON map rather than a nested, typed
/// [UserProfileDto] field to keep this class's freezed codegen simple; it
/// is bridged to/from [UserProfileDto] at the edges via
/// `UserProfileDto.fromJson` / `UserProfileDto.fromEntity(...).toJson()`.
@freezed
class MatchCandidateDto with _$MatchCandidateDto {
  const MatchCandidateDto._();

  const factory MatchCandidateDto({
    required String userId,
    required Map<String, dynamic> profile,
    required double distanceKm,
    required double trustScore,
    required double matchScore,
    required List<String> matchReasons,
  }) = _MatchCandidateDto;

  factory MatchCandidateDto.fromJson(Map<String, dynamic> json) =>
      _$MatchCandidateDtoFromJson(json);

  factory MatchCandidateDto.fromEntity(MatchCandidate entity) => MatchCandidateDto(
        userId: entity.userId,
        profile: UserProfileDto.fromEntity(entity.profile).toJson(),
        distanceKm: entity.distanceKm,
        trustScore: entity.trustScore,
        matchScore: entity.matchScore,
        matchReasons: entity.matchReasons,
      );

  MatchCandidate toEntity() => MatchCandidate(
        userId: userId,
        profile: UserProfileDto.fromJson(profile).toEntity(),
        distanceKm: distanceKm,
        trustScore: trustScore,
        matchScore: matchScore,
        matchReasons: matchReasons,
      );
}
