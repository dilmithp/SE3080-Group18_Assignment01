import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/features/community/data/datasources/community_remote_data_source.dart';
import 'package:elderly_companion/features/community/data/repositories/community_repository_impl.dart';
import 'package:elderly_companion/features/community/domain/entities/community_post.dart';
import 'package:elderly_companion/features/community/domain/repositories/community_repository.dart';
import 'package:elderly_companion/features/community/domain/usecases/create_post_usecase.dart';
import 'package:elderly_companion/features/community/domain/usecases/delete_post_usecase.dart';

/// All Dependency-Inversion wiring for community lives here: presentation
/// and domain depend only on the abstract [CommunityRepository] interface;
/// this file is the only place that knows [CommunityRepositoryImpl] etc.
/// exist.

final communityRemoteDataSourceProvider = Provider<CommunityRemoteDataSource>((ref) {
  return FirebaseCommunityRemoteDataSource(
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(ref.watch(communityRemoteDataSourceProvider));
});

final createPostUseCaseProvider = Provider<CreatePostUseCase>((ref) {
  return CreatePostUseCase(ref.watch(communityRepositoryProvider));
});

final deletePostUseCaseProvider = Provider<DeletePostUseCase>((ref) {
  return DeletePostUseCase(ref.watch(communityRepositoryProvider));
});

/// Live feed of every community post, newest first.
final communityFeedProvider = StreamProvider<List<CommunityPost>>((ref) {
  return ref.watch(communityRepositoryProvider).watchFeed();
});
