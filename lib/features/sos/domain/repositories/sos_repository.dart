import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/sos/domain/entities/sos_alert.dart';

/// Contract for the emergency-SOS workflow: a user in distress triggers an
/// alert; the alert's owner or an admin can mark it resolved.
///
/// Owner: shared across all four components (safety-critical, not owned by
/// one feature) — see SPRINT_3_4_PLAN.md.
abstract class SosRepository {
  Future<Either<Failure, SosAlert>> triggerAlert({
    required String userId,
    double? latitude,
    double? longitude,
    String? note,
  });

  /// This user's own active alert, if any — so [SosButton] can render
  /// "alert active" state and offer "I'm safe now" instead of letting them
  /// fire a second alert on top of an unresolved one.
  Stream<SosAlert?> watchMyActiveAlert(String userId);

  /// Admin-only: live list of every alert still `active`, across all
  /// users, for [ActiveSosAlertsScreen].
  Stream<List<SosAlert>> watchActiveAlerts();

  Future<Either<Failure, SosAlert>> resolveAlert({
    required String alertId,
    required String resolvedBy,
  });
}
