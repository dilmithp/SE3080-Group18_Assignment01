import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/app_user.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';

/// Single business rule: correct the role Firestore holds for a user.
///
/// Not one of the original sign-up/sign-in entry points — this exists so a
/// brand-new [SignInWithEmailLinkUseCase] user (who arrives with a
/// placeholder [UserRole.elderly]) can pick their real role from a
/// one-screen picker before landing on home.
class UpdateUserRoleUseCase {
  const UpdateUserRoleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AppUser>> call({
    required String userId,
    required UserRole role,
  }) async {
    return _repository.updateUserRole(userId: userId, role: role);
  }
}
