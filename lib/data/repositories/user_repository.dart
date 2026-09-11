import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firestore_service.dart';
import '../models/user_model.dart';

/// Reads and writes `users/{uid}` documents.
///
/// Only the fields listed in [UserModel.editableFields] are ever written
/// from here directly (backed by `firestore.rules`). Score-affecting fields
/// (elo/wins/losses/streaks) are never written by the client — they only
/// change as a side effect of the `resolveDuel` Cloud Function.
class UserRepository {
  UserRepository({FirestoreService? firestoreService})
    : _firestore = firestoreService ?? FirestoreService();

  final FirestoreService _firestore;

  Stream<UserModel?> watchUser(String uid) {
    return _firestore.users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Called once, right after a brand-new account signs in for the first
  /// time. Uses `set(..., merge: false)` semantics implicitly via create-if-
  /// missing check in the auth controller, so an existing profile is never
  /// clobbered.
  Future<void> createInitialProfile(UserModel user) async {
    await _firestore.users.doc(user.uid).set(user.toInitialFirestoreMap());
  }

  Future<void> updateProfile(String uid, {String? displayName, String? photoUrl, String? locale}) async {
    final updates = UserModel.editableFields(
      displayName: displayName,
      photoUrl: photoUrl,
      locale: locale,
    );
    if (updates.isEmpty) return;
    await _firestore.users.doc(uid).update(updates);
  }

  /// One-time repair for an account created before `playerId` existed — see
  /// [UserModel.legacyBackfillFields] and the matching narrow update path in
  /// `firestore.rules` that only allows this while `playerId` is absent.
  Future<void> backfillLegacyProfileFields(String uid, {required String playerId, required String displayName}) {
    return _firestore.users
        .doc(uid)
        .update(UserModel.legacyBackfillFields(playerId: playerId, displayName: displayName));
  }

  /// Fetches multiple profiles in one batch, e.g. to show opponent names in
  /// a duel history list. Firestore `whereIn` is capped at 30 ids.
  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    final snapshot = await _firestore.users
        .where(FieldPath.documentId, whereIn: uids.take(30).toList())
        .get();
    return snapshot.docs.map(UserModel.fromFirestore).toList();
  }
}
