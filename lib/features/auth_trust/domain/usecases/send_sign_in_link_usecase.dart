import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';

/// Single business rule: email [email] a passwordless sign-in link.
class SendSignInLinkUseCase {
  const SendSignInLinkUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> call(String email) async {
    return _repository.sendSignInLinkToEmail(email);
  }
}
