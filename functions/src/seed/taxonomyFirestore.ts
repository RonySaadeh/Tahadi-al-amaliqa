import { db, FieldValue } from "../lib/admin";
import { CATEGORIES, CATEGORY_GROUPS } from "./categoryTaxonomy";

/**
 * Firestore writes for the category taxonomy, used by
 * `seedPregeneratedQuestions.ts` before it uploads the hand-written starter
 * question pool.
 */

export async function ensureCategoryGroups(): Promise<void> {
  const batch = db.batch();
  for (const group of CATEGORY_GROUPS) {
    batch.set(
      db.collection("categoryGroups").doc(group.id),
      {
        name: group.name,
        nameEn: group.nameEn,
        order: group.order,
        iconKey: group.iconKey,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  await batch.commit();
  console.log(`Ensured ${CATEGORY_GROUPS.length} category groups.`);
}

/** Creates the category doc if it doesn't already exist. For one that
 * already exists, merge-updates only the display-text fields (name,
 * nameEn, description, descriptionEn, groupId) so re-running the seed
 * script after editing `categoryTaxonomy.ts` backfills text changes —
 * `questionCount`, `ownerId`, and `createdAt` are never touched here. */
export async function ensureCategory(seed: (typeof CATEGORIES)[number]): Promise<void> {
  const ref = db.collection("categories").doc(seed.id);
  const snap = await ref.get();

  const textFields = {
    name: seed.name,
    nameEn: seed.nameEn,
    description: seed.description,
    descriptionEn: seed.descriptionEn,
    groupId: seed.groupId,
  };

  if (!snap.exists) {
    await ref.set({
      ...textFields,
      ownerId: null,
      ownerDisplayName: null,
      questionCount: 0,
      createdAt: FieldValue.serverTimestamp(),
    });
    console.log(`Created category "${seed.name}" (${seed.id})`);
    return;
  }

  await ref.set(textFields, { merge: true });
}
