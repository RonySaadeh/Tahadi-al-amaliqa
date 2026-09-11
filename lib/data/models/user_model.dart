import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/app_constants.dart';

/// A player's public profile, stored at `users/{uid}`.
///
/// `elo`, `wins`, `losses`, `currentStreak` and `bestStreak` are only ever
/// changed by the `resolveDuel` Cloud Function — see `firestore.rules` for
/// the rule that blocks clients from writing them directly. The client may
/// only update `displayName`, `photoUrl` and `locale` (see
/// [UserModel.editableFields]).
class UserModel extends Equatable {
  const UserModel({
    required this.uid,
    required this.playerId,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.elo = AppConstants.startingElo,
    this.wins = 0,
    this.losses = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.ownedCategoryIds = const [],
    required this.createdAt,
    this.locale = 'en',
    this.categoryWins = const {},
    this.lastActiveAt,
  });

  final String uid;

  /// A short, shareable code (e.g. `K7QX2M9P`) a player can hand another
  /// player so they can find and add them without knowing/typing an exact
  /// display name — see [generatePlayerId] and
  /// `FriendsRepository.searchUsers`. Generated once at account creation and
  /// never changes.
  final String playerId;
  final String displayName;
  final String email;
  final String? photoUrl;
  final int elo;
  final int wins;
  final int losses;
  final int currentStreak;
  final int bestStreak;
  final List<String> ownedCategoryIds;
  final DateTime createdAt;
  final String locale;

  /// categoryId -> wins in that category, written by `resolveDuel`'s
  /// `updatePlayerAfterDuel` alongside the global `wins` counter. Absent for
  /// any category this player hasn't won a duel in yet — see [winsInCategory].
  final Map<String, int> categoryWins;

  /// Stamped by the client itself via `FriendsRepository.updatePresence`,
  /// not a Cloud Function — see the narrow presence-only path in
  /// `firestore.rules`. Null until this player's first heartbeat. "Online"
  /// is derived from this (recent enough), not stored as its own flag — see
  /// `core/utils/presence.dart`.
  final DateTime? lastActiveAt;

  int get totalDuels => wins + losses;

  bool get canCreateHomeTurf => ownedCategoryIds.length < AppConstants.maxHomeTurfCategories;

  int winsInCategory(String categoryId) => categoryWins[categoryId] ?? 0;

  /// An 8-character shareable code from an alphabet with the visually
  /// confusable characters (`0`/`O`, `1`/`I`/`L`) removed, so a code read
  /// aloud or copy-pasted is never ambiguous. Not guaranteed globally unique
  /// the way `uid` is — at 32^8 (~1.1 trillion) combinations a collision is
  /// astronomically unlikely for this app's scale, and a duplicate would
  /// only ever mean `searchUsers`'s exact-match returns two people instead
  /// of one, never a security issue (it's a public handle, not a secret).
  static String generatePlayerId({Random? random}) {
    const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
    final rng = random ?? Random.secure();
    return List.generate(8, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel(
      uid: doc.id,
      // Empty for accounts created before Player ID shipped — self-healed
      // on their next profile-screen visit, see `ProfileScreen`'s
      // `ref.listen(currentUserProvider, ...)`.
      playerId: data['playerId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      elo: (data['elo'] as num?)?.toInt() ?? AppConstants.startingElo,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      losses: (data['losses'] as num?)?.toInt() ?? 0,
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (data['bestStreak'] as num?)?.toInt() ?? 0,
      ownedCategoryIds: List<String>.from(data['ownedCategoryIds'] as List? ?? const []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      locale: data['locale'] as String? ?? 'en',
      categoryWins: _parseCategoryWins(data['categoryStats']),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, int> _parseCategoryWins(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <String, int>{};
    for (final entry in raw.entries) {
      final stats = entry.value;
      if (stats is Map && stats['wins'] != null) {
        result[entry.key as String] = (stats['wins'] as num).toInt();
      }
    }
    return result;
  }

  /// Full document written once, on first sign-in only.
  Map<String, dynamic> toInitialFirestoreMap() => {
    'playerId': playerId,
    'displayName': displayName,
    'displayNameLower': displayName.toLowerCase(),
    'email': email,
    'photoUrl': photoUrl,
    'elo': AppConstants.startingElo,
    'wins': 0,
    'losses': 0,
    'currentStreak': 0,
    'bestStreak': 0,
    'ownedCategoryIds': <String>[],
    'createdAt': FieldValue.serverTimestamp(),
    'locale': locale,
  };

  /// The only fields a client is allowed to update directly (matches
  /// `firestore.rules`). Everything score-related goes through Cloud
  /// Functions instead. `displayNameLower` is derived and kept in lockstep
  /// with `displayName` here rather than left for the caller to remember —
  /// `firestore.rules` also re-derives and checks it.
  static Map<String, dynamic> editableFields({String? displayName, String? photoUrl, String? locale}) {
    return {
      if (displayName != null) 'displayName': displayName,
      if (displayName != null) 'displayNameLower': displayName.toLowerCase(),
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (locale != null) 'locale': locale,
    };
  }

  /// One-time repair for an account created before Player ID /
  /// case-insensitive search existed — see `firestore.rules`'s
  /// `!('playerId' in resource.data)` update branch, which only allows this
  /// exact write, and only once.
  static Map<String, dynamic> legacyBackfillFields({required String playerId, required String displayName}) {
    return {'playerId': playerId, 'displayNameLower': displayName.toLowerCase()};
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    int? elo,
    int? wins,
    int? losses,
    int? currentStreak,
    int? bestStreak,
    List<String>? ownedCategoryIds,
    String? locale,
    Map<String, int>? categoryWins,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      uid: uid,
      playerId: playerId,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      elo: elo ?? this.elo,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      ownedCategoryIds: ownedCategoryIds ?? this.ownedCategoryIds,
      createdAt: createdAt,
      locale: locale ?? this.locale,
      categoryWins: categoryWins ?? this.categoryWins,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    playerId,
    displayName,
    email,
    photoUrl,
    elo,
    wins,
    losses,
    currentStreak,
    bestStreak,
    ownedCategoryIds,
    createdAt,
    locale,
    categoryWins,
    lastActiveAt,
  ];
}
