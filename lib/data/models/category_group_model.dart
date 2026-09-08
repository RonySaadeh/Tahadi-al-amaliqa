import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A section header categories are grouped under in the picker UI (e.g.
/// "Sports" containing "Football General", "Real Madrid", "Barcelona", ...).
/// Stored at `categoryGroups/{groupId}`, seeded once by
/// `functions/src/seed/seedCategoryTaxonomy.ts` — there's no in-app way to
/// create a group. Home-turf categories don't belong to any group.
class CategoryGroupModel extends Equatable {
  const CategoryGroupModel({
    required this.id,
    required this.name,
    required this.order,
    required this.iconKey,
  });

  final String id;
  final String name;
  final int order;

  /// Looked up via `categoryGroupIcon()` in `core/utils/category_icons.dart`
  /// to keep this model free of a Flutter/Material dependency.
  final String iconKey;

  factory CategoryGroupModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CategoryGroupModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      iconKey: data['iconKey'] as String? ?? 'general',
    );
  }

  @override
  List<Object?> get props => [id, name, order, iconKey];
}
