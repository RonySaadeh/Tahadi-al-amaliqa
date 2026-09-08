import { db, FieldValue } from "../lib/admin";
import { CATEGORIES, CATEGORY_GROUPS } from "./categoryTaxonomy";

/**
 * Firestore writes shared by every seed script that populates the category
 * taxonomy — `seedCategoryTaxonomy.ts` (Claude-generated questions) and
 * `seedPregeneratedQuestions.ts` (the hand-written starter pool). Both need
 * the same groups/categories to exist first; this is the one place that
 * logic lives so the two scripts can't drift apart on it.
 */

export async function ensureCategoryGroups(): Promise<void> {
  const batch = db.batch();
  for (const group of CATEGORY_GROUPS) {
    batch.set(
      db.collection("categoryGroups").doc(group.id),
      {
        name: group.name,
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

/** Creates the category doc if it doesn't already exist. Never overwrites
 * an existing one, so re-running a seed script is always safe. */
export async function ensureCategory(seed: (typeof CATEGORIES)[number]): Promise<void> {
  const ref = db.collection("categories").doc(seed.id);
  const snap = await ref.get();
  if (snap.exists) return;

  await ref.set({
    name: seed.name,
    description: seed.description,
    ownerId: null,
    ownerDisplayName: null,
    groupId: seed.groupId,
    questionCount: 0,
    createdAt: FieldValue.serverTimestamp(),
  });
  console.log(`Created category "${seed.name}" (${seed.id})`);
}
