import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/features/sos/data/datasources/sos_remote_data_source.dart';
import 'package:elderly_companion/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:elderly_companion/features/sos/domain/entities/sos_alert.dart';
import 'package:elderly_companion/features/sos/domain/repositories/sos_repository.dart';
import 'package:elderly_companion/features/sos/domain/usecases/resolve_sos_alert_usecase.dart';
import 'package:elderly_companion/features/sos/domain/usecases/trigger_sos_alert_usecase.dart';

final sosRemoteDataSourceProvider = Provider<SosRemoteDataSource>((ref) {
  return FirebaseSosRemoteDataSource(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  return SosRepositoryImpl(ref.watch(sosRemoteDataSourceProvider));
});

final triggerSosAlertUseCaseProvider = Provider<TriggerSosAlertUseCase>((ref) {
  return TriggerSosAlertUseCase(ref.watch(sosRepositoryProvider));
});

final resolveSosAlertUseCaseProvider = Provider<ResolveSosAlertUseCase>((ref) {
  return ResolveSosAlertUseCase(ref.watch(sosRepositoryProvider));
});

/// This user's own active alert, if any — null once resolved or if they've
/// never triggered one.
final mySosAlertProvider = StreamProvider.family<SosAlert?, String>((ref, userId) {
  return ref.watch(sosRepositoryProvider).watchMyActiveAlert(userId);
});

/// Admin-only: every alert still active, across all users.
final activeSosAlertsProvider = StreamProvider<List<SosAlert>>((ref) {
  return ref.watch(sosRepositoryProvider).watchActiveAlerts();
});
