import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin generic wrapper around [FirebaseFirestore]. Contains no business
/// logic and no knowledge of any feature's schema — data sources call this
/// with their own `fromJson`/`toJson` converters. Keeping Firestore calls
/// behind this service (rather than sprinkling `FirebaseFirestore.instance`
/// through every data source) means we only ever have one place that talks
/// to the raw SDK.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _firestore.collection(path);

  Future<T?> getDocument<T>({
    required String collectionPath,
    required String docId,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final snapshot = await _firestore.collection(collectionPath).doc(docId).get();
    final data = snapshot.data();
    if (data == null) return null;
    return fromJson(data);
  }

  Stream<T?> watchDocument<T>({
    required String collectionPath,
    required String docId,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return _firestore.collection(collectionPath).doc(docId).snapshots().map(
          (snapshot) => snapshot.data() == null ? null : fromJson(snapshot.data()!),
        );
  }

  Future<void> setDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) {
    return _firestore
        .collection(collectionPath)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) {
    return _firestore.collection(collectionPath).doc(docId).delete();
  }

  Future<List<T>> getCollection<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> json) fromJson,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => fromJson(doc.data())).toList();
  }

  Stream<List<T>> watchCollection<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> json) fromJson,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => fromJson(doc.data())).toList(),
        );
  }

  String newDocId(String collectionPath) =>
      _firestore.collection(collectionPath).doc().id;
}
