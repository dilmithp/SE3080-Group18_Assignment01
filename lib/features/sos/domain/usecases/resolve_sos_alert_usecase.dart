import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/sos/domain/entities/sos_alert.dart';
import 'package:elderly_companion/features/sos/domain/repositories/sos_repository.dart';

/// Single business rule: an alert's owner ("I'm safe now") or an admin
/// marks it resolved. Who's allowed to do so is enforced server-side by
/// `firestore.rules`, not here.
class ResolveSosAlertUseCase {
  const ResolveSosAlertUseCase(this._repository);

  final SosRepository _repository;

  Future<Either<Failure, SosAlert>> call({
    required String alertId,
    required String resolvedBy,
  }) {
    return _repository.resolveAlert(alertId: alertId, resolvedBy: resolvedBy);
  }
}
