import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/app_user.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';

/// Single business rule: register a new account with a chosen [UserRole].
class SignUpWithEmailUseCase {
  const SignUpWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    return _repository.signUpWithEmail(
      email: email,
      password: password,
      phone: phone,
      role: role,
    );
  }
}
