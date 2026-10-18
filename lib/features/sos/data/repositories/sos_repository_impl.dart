import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/sos/data/datasources/sos_remote_data_source.dart';
import 'package:elderly_companion/features/sos/domain/entities/sos_alert.dart';
import 'package:elderly_companion/features/sos/domain/repositories/sos_repository.dart';

/// Satisfies [SosRepository] by delegating to [_dataSource] and mapping
/// data-layer exceptions to [Failure]s.
class SosRepositoryImpl implements SosRepository {
  const SosRepositoryImpl(this._dataSource);

  final SosRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, SosAlert>> triggerAlert({
    required String userId,
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    try {
      final dto = await _dataSource.triggerAlert(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        note: note,
      );
      return Right(dto.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<SosAlert?> watchMyActiveAlert(String userId) {
    return _dataSource.watchMyActiveAlert(userId).map((dto) => dto?.toEntity());
  }

  @override
  Stream<List<SosAlert>> watchActiveAlerts() {
    return _dataSource
        .watchActiveAlerts()
        .map((dtos) => dtos.map((dto) => dto.toEntity()).toList());
  }

  @override
  Future<Either<Failure, SosAlert>> resolveAlert({
    required String alertId,
    required String resolvedBy,
  }) async {
    try {
      final dto = await _dataSource.resolveAlert(
        alertId: alertId,
        resolvedBy: resolvedBy,
      );
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
