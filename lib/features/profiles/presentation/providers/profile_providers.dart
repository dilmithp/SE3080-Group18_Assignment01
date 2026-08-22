import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/features/profiles/data/datasources/profiles_remote_data_source.dart';
import 'package:elderly_companion/features/profiles/data/repositories/profile_repository_impl.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';
import 'package:elderly_companion/features/profiles/domain/repositories/profile_repository.dart';
import 'package:elderly_companion/features/profiles/domain/usecases/get_profile_usecase.dart';
import 'package:elderly_companion/features/profiles/domain/usecases/update_profile_usecase.dart';

/// All Dependency-Inversion wiring for profiles lives here: presentation and
/// domain depend only on the abstract [ProfileRepository] interface; this
/// file is the only place that knows [ProfileRepositoryImpl] etc. exist.

final profilesRemoteDataSourceProvider = Provider<ProfilesRemoteDataSource>((ref) {
  return FirebaseProfilesRemoteDataSource(
    firestoreService: ref.watch(firestoreServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profilesRemoteDataSourceProvider));
});

final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.watch(profileRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(profileRepositoryProvider));
});

/// Live view of a user's profile, or `null` if they haven't created one yet.
final profileProvider =
    StreamProvider.family<UserProfile?, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).watchProfile(userId);
});
