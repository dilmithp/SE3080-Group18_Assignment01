import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
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
    try {
      final dto = await _dataSource.signUpWithEmail(
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      return Right(dto.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final dto = await _dataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Right(dto.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _dataSource.authStateChanges().map((dto) => dto?.toEntity());
  }

  @override
  Future<Either<Failure, void>> sendSignInLinkToEmail(String email) async {
    try {
      await _dataSource.sendSignInLinkToEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      final dto = await _dataSource.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      return Right(dto.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  bool isSignInWithEmailLink(String link) {
    return _dataSource.isSignInWithEmailLink(link);
  }

  @override
  Future<Either<Failure, AppUser>> updateUserRole({
    required String userId,
    required UserRole role,
  }) async {
    try {
      final dto = await _dataSource.updateUserRole(userId: userId, role: role);
      return Right(dto.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
