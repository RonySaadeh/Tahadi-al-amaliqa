import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_paths.dart';

/// Typed, centralized Firestore collection references.
///
/// Repositories (see `data/repositories/`) use this instead of calling
/// `FirebaseFirestore.instance.collection('...')` with raw strings
/// scattered everywhere. Every collection has `withConverter` wired up in
/// its repository, so this service just hands back the raw
/// [CollectionReference]/[DocumentReference] — the fromJson/toJson mapping
/// lives with each model.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  FirebaseFirestore get db => _db;

  CollectionReference<Map<String, dynamic>> get users => _db.collection(FirestorePaths.users);

  CollectionReference<Map<String, dynamic>> get categoryGroups =>
      _db.collection(FirestorePaths.categoryGroups);

  CollectionReference<Map<String, dynamic>> get categories =>
      _db.collection(FirestorePaths.categories);

  CollectionReference<Map<String, dynamic>> get questions =>
      _db.collection(FirestorePaths.questions);

  CollectionReference<Map<String, dynamic>> get duels => _db.collection(FirestorePaths.duels);

  CollectionReference<Map<String, dynamic>> get duelInvites =>
      _db.collection(FirestorePaths.duelInvites);

  CollectionReference<Map<String, dynamic>> get openLobbies =>
      _db.collection(FirestorePaths.openLobbies);

  CollectionReference<Map<String, dynamic>> get leaderboardPairings =>
      _db.collection(FirestorePaths.leaderboardPairings);

  CollectionReference<Map<String, dynamic>> duelRounds(String duelId) =>
      duels.doc(duelId).collection(FirestorePaths.rounds);

  CollectionReference<Map<String, dynamic>> roundAnswers(String duelId, int roundNumber) =>
      duelRounds(duelId).doc(roundNumber.toString()).collection(FirestorePaths.answers);
}
