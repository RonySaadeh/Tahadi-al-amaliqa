/**
 * One-off admin script: creates every group + category in
 * `categoryTaxonomy.ts` and uploads the hand-written starter question pool
 * from `pregeneratedQuestions.ts` — 5 questions per category, written by
 * Claude directly in conversation rather than fetched through a live API
 * call. That's the whole point of this script existing separately from
 * `seedCategoryTaxonomy.ts`: it needs NO `ANTHROPIC_API_KEY` and makes NO
 * Claude API calls — only Firebase Admin credentials, same as
 * `importOpenTriviaDb.ts`.
 *
 * This is a starting pool (5/category), not the final word. Once you have
 * your own Claude API key, run `seedCategoryTaxonomy.ts` to top any
 * category up with a much larger AI-generated batch — it skips nothing
 * here, it just adds more.
 */
import { db, FieldValue } from "../lib/admin";
import { CATEGORIES } from "./categoryTaxonomy";
import { PREGENERATED_QUESTIONS } from "./pregeneratedQuestions";
import { ensureCategory, ensureCategoryGroups } from "./taxonomyFirestore";

async function seedAll(): Promise<void> {
  await ensureCategoryGroups();

  for (const category of CATEGORIES) {
    await ensureCategory(category);

    const questions = PREGENERATED_QUESTIONS[category.id];
    if (!questions || questions.length === 0) {
      console.warn(`  ${category.name}: no pregenerated questions found for id "${category.id}", skipping`);
      continue;
    }

    const batch = db.batch();
    for (const question of questions) {
      batch.set(db.collection("questions").doc(), {
        categoryId: category.id,
        ownerId: null,
        questionText: question.questionText,
        options: question.options,
        correctAnswerIndex: question.correctAnswerIndex,
        difficulty: question.difficulty,
        source: "llm",
        language: category.language,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    batch.update(db.collection("categories").doc(category.id), {
      questionCount: FieldValue.increment(questions.length),
    });
    await batch.commit();

    console.log(`  ${category.name}: +${questions.length} questions`);
  }

  console.log("Done.");
}

if (require.main === module) {
  seedAll()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

/**
 * Running this:
 *
 * Only needs Firebase Admin credentials — no Anthropic key, no billing.
 *
 *   cd functions && npm run build
 *   GOOGLE_APPLICATION_CREDENTIALS=<path-to-a-service-account-key.json> \
 *     node lib/seed/seedPregeneratedQuestions.js
 *
 * Against the local emulator instead of your real project:
 *   firebase emulators:start --only firestore
 *   # in another terminal:
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 GCLOUD_PROJECT=<your-project-id> \
 *     node lib/seed/seedPregeneratedQuestions.js
 *
 * Safe to re-run: categories use deterministic ids and are never
 * recreated, but re-running DOES add another copy of these same 5
 * questions per category each time — run it once, then use
 * `seedCategoryTaxonomy.ts` (needs a Claude key) to add more variety
 * instead of re-running this one repeatedly.
 */
