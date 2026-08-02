import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elderly_companion/features/auth_trust/domain/entities/app_user.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';

part 'app_user_dto.freezed.dart';
part 'app_user_dto.g.dart';

/// Firestore-shaped DTO for the `users` collection. Converts to/from the
/// pure [AppUser] domain entity — see [toEntity] / [AppUserDto.fromEntity].
/// Dates are stored as epoch milliseconds so this class stays plain-JSON
/// (no custom `Timestamp` converter needed); the data source is
/// responsible for bridging Firestore's `Timestamp` type at the boundary.
@freezed
class AppUserDto with _$AppUserDto {
  const AppUserDto._();

  const factory AppUserDto({
    required String id,
    required String email,
    required String phone,
    required String role,
    required bool isVerified,
    required int createdAtMillis,
  }) = _AppUserDto;

  factory AppUserDto.fromJson(Map<String, dynamic> json) =>
      _$AppUserDtoFromJson(json);

  factory AppUserDto.fromEntity(AppUser entity) => AppUserDto(
        id: entity.id,
        email: entity.email,
        phone: entity.phone,
        role: entity.role.name,
        isVerified: entity.isVerified,
        createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      );

  AppUser toEntity() => AppUser(
        id: id,
        email: email,
        phone: phone,
        role: UserRole.values.byName(role),
        isVerified: isVerified,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      );
}
