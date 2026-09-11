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

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel(
      uid: doc.id,
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
    'displayName': displayName,
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
  /// Functions instead.
  static Map<String, dynamic> editableFields({String? displayName, String? photoUrl, String? locale}) {
    return {
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (locale != null) 'locale': locale,
    };
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
