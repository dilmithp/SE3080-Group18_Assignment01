import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/profiles/data/datasources/profiles_remote_data_source.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:elderly_companion/features/profiles/domain/repositories/profile_repository.dart';

/// Satisfies [ProfileRepository]. Every method is stubbed — the job of
/// implementing this class is to call [_dataSource], convert between
/// [UserProfile] and its DTO, catch the exceptions in
/// core/error/exceptions.dart, and map them to a [Failure].
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._dataSource);

  final ProfilesRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, UserProfile>> getProfile(String userId) async {
    throw UnimplementedError('TODO(Perera): implement via $_dataSource');
  }

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    throw UnimplementedError('TODO(Perera): implement via $_dataSource');
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile) async {
    throw UnimplementedError('TODO(Perera): implement via $_dataSource');
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto({
    required String userId,
    required String filePath,
  }) async {
    throw UnimplementedError('TODO(Perera): implement via $_dataSource');
  }
}
