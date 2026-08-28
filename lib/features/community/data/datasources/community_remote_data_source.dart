import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elderly_companion/core/error/exceptions.dart';
import 'package:elderly_companion/core/services/firestore_service.dart';
import 'package:elderly_companion/features/community/data/models/community_post_dto.dart';

/// Firestore collection name for community posts. Not in
/// `core/config/app_config.dart`'s `AppConfig` because this feature's file
/// set is standalone (see the ownership note in docs/DATA_MODEL.md) — kept
/// local to this data source the same way a rename would only ever touch
/// this one file.
const String _communityPostsCollection = 'community_posts';

/// Raw Firebase calls for the community feed. Throws the exceptions in
/// core/error/exceptions.dart; [CommunityRepositoryImpl] translates those
/// into [Failure]s.
abstract class CommunityRemoteDataSource {
  Future<CommunityPostDto> createPost({
    required String authorId,
    required String authorName,
    String? authorPhotoUrl,
    required String text,
  });

  /// All posts, newest first, capped at [limit].
  Stream<List<CommunityPostDto>> watchFeed({int limit = 100});

  /// Deletes [postId] on behalf of [authorId]. Throws
  /// [NotFoundException] if the post no longer exists and
  /// [PermissionException] if [authorId] did not write it — the
  /// authoritative check still lives in firestore.rules, this is a client-
  /// side fast-fail so the UI can show a clear message rather than a raw
  /// Firestore permission error.
  Future<void> deletePost({
    required String postId,
    required String authorId,
  });
}

class FirebaseCommunityRemoteDataSource implements CommunityRemoteDataSource {
  FirebaseCommunityRemoteDataSource({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  @override
  Future<CommunityPostDto> createPost({
    required String authorId,
    required String authorName,
    String? authorPhotoUrl,
    required String text,
  }) async {
    try {
      final id = _firestoreService.newDocId(_communityPostsCollection);
      final now = Timestamp.now();
      await _firestoreService.setDocument(
        collectionPath: _communityPostsCollection,
        docId: id,
        data: {
          'authorId': authorId,
          'authorName': authorName,
          'authorPhotoUrl': authorPhotoUrl,
          'text': text,
          'createdAt': now,
        },
      );
      return CommunityPostDto(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        text: text,
        createdAtMillis: now.millisecondsSinceEpoch,
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Stream<List<CommunityPostDto>> watchFeed({int limit = 100}) {
    return _firestoreService
        .collection(_communityPostsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _dtoFromData(doc.id, doc.data())).toList(),
        );
  }

  @override
  Future<void> deletePost({
    required String postId,
    required String authorId,
  }) async {
    try {
      final docRef =
          _firestoreService.collection(_communityPostsCollection).doc(postId);
      final snapshot = await docRef.get();
      final data = snapshot.data();
      if (data == null) {
        throw const NotFoundException('Post not found.');
      }
      if (data['authorId'] != authorId) {
        throw const PermissionException('You can only delete your own posts.');
      }
      await _firestoreService.deleteDocument(
        collectionPath: _communityPostsCollection,
        docId: postId,
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Server error.');
    } on NotFoundException {
      rethrow;
    } on PermissionException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  CommunityPostDto _dtoFromData(String id, Map<String, dynamic> data) {
    return CommunityPostDto(
      id: id,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      text: data['text'] as String,
      createdAtMillis: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
    );
  }
}
