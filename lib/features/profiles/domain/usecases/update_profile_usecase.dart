import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:elderly_companion/features/profiles/domain/repositories/profile_repository.dart';

/// Single business rule: persist edits to a user's profile.
class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, UserProfile>> call(UserProfile profile) async {
    return _repository.updateProfile(profile);
  }
}
