import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/app_enums.dart';

/// A pending challenge from one friend to another, stored at
/// `duelInvites/{inviteId}`. Created by `sendDuelChallenge` and resolved by
/// `respondToDuelChallenge` (which creates the actual [DuelModel] on
/// accept). Client-read-only, like everything duel-related.
class DuelInviteModel extends Equatable {
  const DuelInviteModel({
    required this.id,
    required this.fromUserId,
    required this.fromDisplayName,
    required this.toUserId,
    required this.categoryId,
    required this.categoryName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String fromUserId;
  final String fromDisplayName;
  final String toUserId;
  final String categoryId;
  final String categoryName;
  final DuelInviteStatus status;
  final DateTime createdAt;

  factory DuelInviteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return DuelInviteModel(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      fromDisplayName: data['fromDisplayName'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      status: DuelInviteStatus.fromString(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    fromUserId,
    fromDisplayName,
    toUserId,
    categoryId,
    categoryName,
    status,
    createdAt,
  ];
}
