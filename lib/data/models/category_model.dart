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
    this.nameEn,
    required this.description,
    this.descriptionEn,
    this.ownerId,
    this.ownerDisplayName,
    this.groupId,
    this.questionCount = 0,
    required this.createdAt,
  });

  final String id;

  /// Arabic display name — the primary/default locale, always present.
  final String name;

  /// English display name — only ever set for the seeded global taxonomy
  /// (see `functions/src/seed/categoryTaxonomy.ts`). Null for home-turf
  /// categories, since those are user-typed in whichever language their
  /// owner wrote them in and can't be auto-translated.
  final String? nameEn;

  final String description;
  final String? descriptionEn;
  final String? ownerId;
  final String? ownerDisplayName;

  /// Which [CategoryGroupModel] this belongs to in the category picker
  /// (e.g. "Sports"). Null for home-turf categories — grouping only
  /// applies to the seeded global taxonomy; see
  /// `functions/src/seed/categoryTaxonomy.ts`.
  final String? groupId;
  final int questionCount;
  final DateTime createdAt;

  bool get isHomeTurf => ownerId != null;

  /// Picks [nameEn] when `locale` is `'en'` and one was seeded, otherwise
  /// [name] — matches `users/{uid}.locale` ('ar'/'en'), see
  /// `currentUserProvider`.
  String displayName(String? locale) => (locale == 'en' && (nameEn?.isNotEmpty ?? false)) ? nameEn! : name;

  /// Same locale rule as [displayName], for [description].
  String displayDescription(String? locale) =>
      (locale == 'en' && (descriptionEn?.isNotEmpty ?? false)) ? descriptionEn! : description;

  factory CategoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      nameEn: data['nameEn'] as String?,
      description: data['description'] as String? ?? '',
      descriptionEn: data['descriptionEn'] as String?,
      ownerId: data['ownerId'] as String?,
      ownerDisplayName: data['ownerDisplayName'] as String?,
      groupId: data['groupId'] as String?,
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    nameEn,
    description,
    descriptionEn,
    ownerId,
    groupId,
    questionCount,
    createdAt,
  ];
}
