import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/profiles/data/datasources/profiles_remote_data_source.dart';
import 'package:elderly_companion/features/profiles/data/models/user_profile_dto.dart';
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
    try {
      final dto = await _dataSource.getProfile(userId);
      return Right(dto.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _dataSource.watchProfile(userId).map((dto) => dto?.toEntity());
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile) async {
    try {
      final dto = await _dataSource.updateProfile(UserProfileDto.fromEntity(profile));
      return Right(dto.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto({
    required String userId,
    required String filePath,
  }) async {
    try {
      final url = await _dataSource.uploadProfilePhoto(
        userId: userId,
        filePath: filePath,
      );
      return Right(url);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
