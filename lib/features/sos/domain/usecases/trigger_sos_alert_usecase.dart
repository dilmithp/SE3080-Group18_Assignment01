import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/sos/domain/entities/sos_alert.dart';
import 'package:elderly_companion/features/sos/domain/repositories/sos_repository.dart';

/// Single business rule: a user in distress raises an emergency alert.
/// Texting their emergency contact is a separate, device-local step the
/// caller (SosButton) drives directly via url_launcher — this use case only
/// owns the durable Firestore record admins can see and act on.
class TriggerSosAlertUseCase {
  const TriggerSosAlertUseCase(this._repository);

  final SosRepository _repository;

  Future<Either<Failure, SosAlert>> call({
    required String userId,
    double? latitude,
    double? longitude,
    String? note,
  }) {
    return _repository.triggerAlert(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      note: note,
    );
  }
}
