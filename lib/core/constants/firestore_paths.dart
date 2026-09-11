/// Central place for every Firestore collection/subcollection name.
///
/// Nothing here is clever — it exists so a typo in a collection name is a
/// single compile error instead of a silently-empty query somewhere in the
/// app. If you rename a collection, this is the only file (besides
/// `firestore.rules` and the Cloud Functions) that needs to change.
class FirestorePaths {
  const FirestorePaths._();

  static const String users = 'users';
  static const String categoryGroups = 'categoryGroups';
  static const String categories = 'categories';
  static const String questions = 'questions';
  static const String duels = 'duels';
  static const String rounds = 'rounds'; // subcollection of duels/{duelId}
  static const String answers = 'answers'; // subcollection of rounds/{n}
  static const String duelInvites = 'duelInvites';
  static const String openLobbies = 'openLobbies';
  static const String leaderboardPairings = 'leaderboardPairings';
  static const String friendships = 'friendships';
  static const String notifications = 'notifications';

  static String duelRounds(String duelId) => '$duels/$duelId/$rounds';

  static String roundAnswers(String duelId, int roundNumber) =>
      '$duels/$duelId/$rounds/$roundNumber/$answers';

  /// Deterministic doc id for a head-to-head pairing doc, independent of
  /// who challenged whom, so both players read/write the same document.
  static String pairingId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
