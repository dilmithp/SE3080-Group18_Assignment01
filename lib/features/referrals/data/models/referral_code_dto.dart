import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/referrals/domain/entities/referral_code.dart';

part 'referral_code_dto.freezed.dart';
part 'referral_code_dto.g.dart';

/// Firestore-shaped DTO for the `referral_codes` collection (doc ID = the
/// code itself). `createdAt` is stored as epoch milliseconds so this class
/// stays plain-JSON — the data source bridges Firestore's `Timestamp` type
/// at the boundary.
@freezed
abstract class ReferralCodeDto with _$ReferralCodeDto {
  const ReferralCodeDto._();

  const factory ReferralCodeDto({
    required String code,
    required String ownerId,
    required int createdAtMillis,
  }) = _ReferralCodeDto;

  factory ReferralCodeDto.fromJson(Map<String, dynamic> json) =>
      _$ReferralCodeDtoFromJson(json);

  factory ReferralCodeDto.fromEntity(ReferralCode entity) => ReferralCodeDto(
        code: entity.code,
        ownerId: entity.ownerId,
        createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      );

  ReferralCode toEntity() => ReferralCode(
        code: code,
        ownerId: ownerId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      );
}
