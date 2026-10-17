import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';

/// Single business rule: sign the user out of every device.
class SignOutEverywhereUseCase {
  const SignOutEverywhereUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call() async {
    return _repository.signOutEverywhere();
  }
}
