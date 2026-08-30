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

  /// Emails [email] a passwordless sign-in link. On web the link points back
  /// at the app's own origin (see `ActionCodeSettings` in the Firebase data
  /// source) so opening it lands back in this app with `handleCodeInApp`.
  Future<Either<Failure, void>> sendSignInLinkToEmail(String email);

  /// Completes a passwordless sign-in started by [sendSignInLinkToEmail].
  /// [emailLink] is the full URL the user opened (e.g. `Uri.base.toString()`
  /// on web) and [email] must be the same address the link was sent to.
  ///
  /// If this is the first time this uid has ever signed in, a minimal
  /// `users/{uid}` doc is created with a placeholder [UserRole.elderly] role
  /// (there is no signup form in this flow to collect a real one) — the
  /// returned [AppUser] carries that placeholder until the caller corrects
  /// it via [updateUserRole].
  Future<Either<Failure, AppUser>> signInWithEmailLink({
    required String email,
    required String emailLink,
  });

  /// Pure check, no network call — mirrors `FirebaseAuth.isSignInWithEmailLink`.
  /// Callers use this against `Uri.base.toString()` on startup to detect
  /// "the app was just opened from an emailed sign-in link".
  bool isSignInWithEmailLink(String link);

  /// Corrects the role Firestore holds for [userId]. Not part of the
  /// original three auth entry points — added as the "follow-up set my role
  /// write" seam for [signInWithEmailLink]'s brand-new-user case, so a user
  /// who lands with the [UserRole.elderly] placeholder can pick their real
  /// role from a one-screen picker before reaching home.
  Future<Either<Failure, AppUser>> updateUserRole({
    required String userId,
    required UserRole role,
  });
}
