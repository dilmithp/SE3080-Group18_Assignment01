import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/di/injection.dart';
import 'package:elderly_companion/features/auth_trust/data/datasources/auth_trust_remote_data_source.dart';
import 'package:elderly_companion/features/auth_trust/data/repositories/auth_repository_impl.dart';
import 'package:elderly_companion/features/auth_trust/data/repositories/trust_score_repository_impl.dart';
import 'package:elderly_companion/features/auth_trust/data/repositories/verification_repository_impl.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/app_user.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/verification_request.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/auth_repository.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/trust_score_repository.dart';
import 'package:elderly_companion/features/auth_trust/domain/repositories/verification_repository.dart';
import 'package:elderly_companion/features/auth_trust/domain/usecases/get_trust_score_usecase.dart';
import 'package:elderly_companion/features/auth_trust/domain/usecases/review_verification_request_usecase.dart';
import 'package:elderly_companion/features/auth_trust/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:elderly_companion/features/auth_trust/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:elderly_companion/features/auth_trust/domain/usecases/submit_verification_request_usecase.dart';

/// All Dependency-Inversion wiring for auth_trust lives here: presentation
/// and domain depend only on the abstract repository interfaces above;
/// this file is the only place that knows [AuthRepositoryImpl] etc. exist.

final authTrustRemoteDataSourceProvider = Provider<AuthTrustRemoteDataSource>((ref) {
  return FirebaseAuthTrustRemoteDataSource(
    firebaseAuth: FirebaseAuth.instance,
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authTrustRemoteDataSourceProvider));
});

/// The real, Firebase-backed replacement for `app_router.dart`'s old
/// placeholder `isAuthenticatedProvider`. Emits the currently signed-in
/// [AppUser], or `null` when signed out.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepositoryImpl(ref.watch(authTrustRemoteDataSourceProvider));
});

final trustScoreRepositoryProvider = Provider<TrustScoreRepository>((ref) {
  return TrustScoreRepositoryImpl(ref.watch(authTrustRemoteDataSourceProvider));
});

final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>((ref) {
  return SignInWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final signUpWithEmailUseCaseProvider = Provider<SignUpWithEmailUseCase>((ref) {
  return SignUpWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final submitVerificationRequestUseCaseProvider =
    Provider<SubmitVerificationRequestUseCase>((ref) {
  return SubmitVerificationRequestUseCase(ref.watch(verificationRepositoryProvider));
});

final reviewVerificationRequestUseCaseProvider =
    Provider<ReviewVerificationRequestUseCase>((ref) {
  return ReviewVerificationRequestUseCase(ref.watch(verificationRepositoryProvider));
});

final getTrustScoreUseCaseProvider = Provider<GetTrustScoreUseCase>((ref) {
  return GetTrustScoreUseCase(ref.watch(trustScoreRepositoryProvider));
});

/// Live verification status for a given user, for
/// [VerificationScreen] to render without polling.
final verificationStatusProvider =
    StreamProvider.family<VerificationRequest?, String>((ref, userId) {
  return ref.watch(verificationRepositoryProvider).watchVerificationStatus(userId);
});

/// Admin-only live queue of every verification request still awaiting
/// review, for [AdminVerificationQueueScreen].
final pendingVerificationRequestsProvider =
    StreamProvider<List<VerificationRequest>>((ref) {
  return ref.watch(verificationRepositoryProvider).watchPendingVerificationRequests();
});
