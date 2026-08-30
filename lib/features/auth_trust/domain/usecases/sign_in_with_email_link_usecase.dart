import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/app_user.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';

/// Single business rule: complete a passwordless sign-in started by
/// [SendSignInLinkUseCase].
class SignInWithEmailLinkUseCase {
  const SignInWithEmailLinkUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String emailLink,
  }) async {
    return _repository.signInWithEmailLink(email: email, emailLink: emailLink);
  }
}
