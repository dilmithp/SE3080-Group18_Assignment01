import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin generic wrapper around [FirebaseStorage]. No business logic —
/// callers decide the storage path (see [AppConfig] for the shared path
/// constants) and pass in the bytes to upload.
///
/// Takes raw bytes rather than a `dart:io.File` deliberately: this app runs
/// on Flutter Web (the team's dev/demo target — see `flutter run -d
/// chrome`), where `dart:io.File` doesn't exist and throws at runtime.
/// `image_picker`'s `XFile.readAsBytes()` works identically on every
/// platform, so callers should read bytes there and pass them straight
/// through instead of constructing a `File` from `XFile.path`.
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// [contentType] must be set — storage.rules' `isImage()` check requires
  /// an `image/*` content type on every path this app writes to
  /// (verification_documents, profile_photos), and `putData` without
  /// explicit metadata defaults to `application/octet-stream`, which that
  /// rule rejects outright. Pass the picked file's real MIME type where
  /// available (e.g. `XFile.mimeType`), falling back to 'image/jpeg'.
  Future<String> uploadFile({
    required String storagePath,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref(storagePath);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<void> deleteFile(String storagePath) {
    return _storage.ref(storagePath).delete();
  }

  Future<String> getDownloadUrl(String storagePath) {
    return _storage.ref(storagePath).getDownloadURL();
  }
}
