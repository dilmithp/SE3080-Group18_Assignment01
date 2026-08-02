import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/auth_trust/domain/entities/verification_request.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/verification_status.dart';

part 'verification_request_dto.freezed.dart';
part 'verification_request_dto.g.dart';

@freezed
class VerificationRequestDto with _$VerificationRequestDto {
  const VerificationRequestDto._();

  const factory VerificationRequestDto({
    required String id,
    required String userId,
    required String documentUrl,
    required String status,
    String? reviewedBy,
    int? reviewedAtMillis,
  }) = _VerificationRequestDto;

  factory VerificationRequestDto.fromJson(Map<String, dynamic> json) =>
      _$VerificationRequestDtoFromJson(json);

  factory VerificationRequestDto.fromEntity(VerificationRequest entity) =>
      VerificationRequestDto(
        id: entity.id,
        userId: entity.userId,
        documentUrl: entity.documentUrl,
        status: entity.status.name,
        reviewedBy: entity.reviewedBy,
        reviewedAtMillis: entity.reviewedAt?.millisecondsSinceEpoch,
      );

  VerificationRequest toEntity() => VerificationRequest(
        id: id,
        userId: userId,
        documentUrl: documentUrl,
        status: VerificationStatus.values.byName(status),
        reviewedBy: reviewedBy,
        reviewedAt: reviewedAtMillis == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(reviewedAtMillis!),
      );
}
