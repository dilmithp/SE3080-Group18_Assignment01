import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/core/services/notification_service.dart';
import 'package:elderly_companion/core/services/storage_service.dart';

/// Shared, cross-cutting service singletons. Every feature's repository
/// implementation depends on these abstractions-over-Firebase rather than
/// touching `FirebaseFirestore.instance` etc. directly — this is the one
/// place in the app that constructs them.
///
/// Feature-specific wiring (repository interface -> implementation, use
/// case construction) lives beside each feature instead of growing this
/// file into a god-file that every parallel PR has to touch — see
/// `features/<feature>/presentation/providers/`. Those providers `ref.watch`
/// the singletons declared here, so this file is still the single source of
/// truth for *how the app talks to Firebase*, per the Dependency Inversion
/// rule in the README.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
