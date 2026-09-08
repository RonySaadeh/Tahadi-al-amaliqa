import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A trivia category/topic, stored at `categories/{categoryId}`.
///
/// `ownerId` is null for global/seeded categories and set to a user's uid
/// for "home turf" categories they created. All writes go through the
/// `createHomeTurfCategory` Cloud Function (which also enforces the 3
/// categories/user limit) — clients cannot write this collection directly.
class CategoryModel extends Equatable {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    this.ownerId,
    this.ownerDisplayName,
    this.questionCount = 0,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String? ownerId;
  final String? ownerDisplayName;
  final int questionCount;
  final DateTime createdAt;

  bool get isHomeTurf => ownerId != null;

  factory CategoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      ownerId: data['ownerId'] as String?,
      ownerDisplayName: data['ownerDisplayName'] as String?,
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, description, ownerId, questionCount, createdAt];
}
