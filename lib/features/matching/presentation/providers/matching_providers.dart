import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/features/matching/data/datasources/matching_remote_data_source.dart';
import 'package:elderly_companion/features/matching/data/repositories/matching_repository_impl.dart';
import 'package:elderly_companion/features/matching/domain/repositories/matching_repository.dart';
import 'package:elderly_companion/features/matching/domain/usecases/find_matches_usecase.dart';

/// All Dependency-Inversion wiring for matching lives here: presentation
/// and domain depend only on the abstract [MatchingRepository] /
/// [MatchingStrategy] interfaces above; this file is the only place that
/// knows [MatchingRepositoryImpl] etc. exist.

final matchingRemoteDataSourceProvider = Provider<MatchingRemoteDataSource>((ref) {
  return FirebaseMatchingRemoteDataSource(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  return MatchingRepositoryImpl(ref.watch(matchingRemoteDataSourceProvider));
});

/// Strategy is no longer injected here — [FindMatchesUseCase] resolves it
/// per call from the search's own `MatchCriteria.strategyType`
/// (see domain/strategies/matching_strategy.dart).
final findMatchesUseCaseProvider = Provider<FindMatchesUseCase>((ref) {
  return FindMatchesUseCase(ref.watch(matchingRepositoryProvider));
});
