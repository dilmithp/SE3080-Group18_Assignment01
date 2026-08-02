import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/data/datasources/auth_trust_remote_data_source.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/app_user.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';

/// Satisfies [AuthRepository]. Every method is stubbed — the job of
/// implementing this class is to call [_dataSource], catch the exceptions
/// in core/error/exceptions.dart, and map them to a [Failure].
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthTrustRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    throw UnimplementedError('TODO(Pathirana): implement via $_dataSource');
  }

  @override
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('TODO(Pathirana): implement via $_dataSource');
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    throw UnimplementedError('TODO(Pathirana): implement via $_dataSource');
  }

  @override
  Stream<AppUser?> authStateChanges() {
    throw UnimplementedError('TODO(Pathirana): implement via $_dataSource');
  }
}
