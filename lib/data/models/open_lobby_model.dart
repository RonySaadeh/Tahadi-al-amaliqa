import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// One entry in the quick-match queue, stored at `openLobbies/{lobbyId}`.
/// Created by `joinOpenLobby` when no waiting opponent is found; `duelId`
/// stays null until another player's `joinOpenLobby` call matches into this
/// entry, at which point the Cloud Function stamps it — see
/// `functions/src/matchmaking/openLobby.ts`. The quick-match screen watches
/// this document purely to notice that happening.
class OpenLobbyModel extends Equatable {
  const OpenLobbyModel({
    required this.id,
    required this.hostId,
    required this.categoryId,
    required this.status,
    this.duelId,
  });

  final String id;
  final String hostId;
  final String categoryId;
  final String status; // 'open' | 'matched'
  final String? duelId;

  factory OpenLobbyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return OpenLobbyModel(
      id: doc.id,
      hostId: data['hostId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      duelId: data['duelId'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, hostId, categoryId, status, duelId];
}
