import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/app_user.dart';
import 'package:elderly_companion/features/auth_trust/domain/entities/user_role.dart';

/// Contract: sign-up, sign-in, sign-out and session/auth-state access only.
/// Split from [VerificationRepository] and [TrustScoreRepository] (Interface
/// Segregation) — a screen that only reads a trust score must not be forced
/// to depend on sign-up methods.
///
/// Owner: Pathirana (features/auth_trust).
abstract class AuthRepository {
  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  });

  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> signOut();

  /// Currently signed-in user, or `null` if signed out. Emits on every
  /// auth-state change (sign-in, sign-out, token refresh).
  Stream<AppUser?> authStateChanges();
}
