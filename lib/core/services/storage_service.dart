import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin generic wrapper around [FirebaseStorage]. No business logic —
/// callers decide the storage path (see [AppConfig] for the shared path
/// constants) and pass in the file to upload.
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadFile({
    required String storagePath,
    required File file,
  }) async {
    final ref = _storage.ref(storagePath);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> deleteFile(String storagePath) {
    return _storage.ref(storagePath).delete();
  }

  Future<String> getDownloadUrl(String storagePath) {
    return _storage.ref(storagePath).getDownloadURL();
  }
}
