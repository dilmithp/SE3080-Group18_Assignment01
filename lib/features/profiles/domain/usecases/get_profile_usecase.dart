import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:elderly_companion/features/profiles/domain/repositories/profile_repository.dart';

/// Single business rule: fetch a user's profile by id.
class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, UserProfile>> call(String userId) async {
    throw UnimplementedError(
      'TODO(Perera): implement via ${_repository.runtimeType}',
    );
  }
}
