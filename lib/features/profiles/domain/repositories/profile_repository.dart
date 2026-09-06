import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:elderly_companion/core/error/failures.dart';
import 'package:elderly_companion/features/profiles/domain/entities/user_profile.dart';

/// Contract: read, watch, update a user's profile, and upload a profile
/// photo. Split from other features' repositories (Interface Segregation) —
/// a screen that only reads a profile must not be forced to depend on
/// matching or scheduling concerns.
///
/// Owner: Perera (features/profiles).
abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile(String userId);

  /// Emits on every change to the given user's profile document, or `null`
  /// if no profile exists yet for that user.
  Stream<UserProfile?> watchProfile(String userId);

  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile);

  /// Uploads [bytes] as the profile photo for [userId] and returns its
  /// public download URL. Callers should read bytes via
  /// `XFile.readAsBytes()` (works on every platform, unlike constructing a
  /// `dart:io.File` from `XFile.path`, which throws on web).
  Future<Either<Failure, String>> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
  });
}
