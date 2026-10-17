import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/referrals/domain/entities/referral.dart';

part 'referral_dto.freezed.dart';
part 'referral_dto.g.dart';

/// Firestore-shaped DTO for the `referrals` collection. `createdAt` is
/// stored as epoch milliseconds so this class stays plain-JSON — the data
/// source bridges Firestore's `Timestamp` type at the boundary.
@freezed
abstract class ReferralDto with _$ReferralDto {
  const ReferralDto._();

  const factory ReferralDto({
    required String id,
    required String code,
    required String referrerId,
    required String referredUserId,
    required String referredName,
    required int createdAtMillis,
  }) = _ReferralDto;

  factory ReferralDto.fromJson(Map<String, dynamic> json) =>
      _$ReferralDtoFromJson(json);

  factory ReferralDto.fromEntity(Referral entity) => ReferralDto(
        id: entity.id,
        code: entity.code,
        referrerId: entity.referrerId,
        referredUserId: entity.referredUserId,
        referredName: entity.referredName,
        createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      );

  Referral toEntity() => Referral(
        id: id,
        code: code,
        referrerId: referrerId,
        referredUserId: referredUserId,
        referredName: referredName,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      );
}
