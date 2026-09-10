/**
 * One-off admin script: creates every group + category in
 * `categoryTaxonomy.ts` and uploads the hand-written starter question pools
 * from `pregeneratedQuestions.ts` (Arabic) and `pregeneratedQuestionsEn.ts`
 * (English) — written by hand rather than fetched through a live API call.
 * It needs only Firebase Admin credentials, same as `importOpenTriviaDb.ts`.
 *
 * Every category ends up with both a `language: "ar"` pool and a
 * `language: "en"` pool (regardless of `CategorySeed.language`, which only
 * controls the category's own display metadata) — `pickNextQuestion` (see
 * `functions/src/scoring/resolveDuel.ts`) picks from whichever pool matches
 * a given duel's `language`.
 */
import { db, FieldValue } from "../lib/admin";
import { CATEGORIES } from "./categoryTaxonomy";
import { PregeneratedQuestion, PREGENERATED_QUESTIONS } from "./pregeneratedQuestions";
import { PREGENERATED_QUESTIONS_EN } from "./pregeneratedQuestionsEn";
import { ensureCategory, ensureCategoryGroups } from "./taxonomyFirestore";

async function seedLanguagePool(
  categoryId: string,
  categoryName: string,
  language: string,
  questions: PregeneratedQuestion[] | undefined,
): Promise<number> {
  if (!questions || questions.length === 0) {
    console.warn(`  ${categoryName} (${language}): no pregenerated questions found for id "${categoryId}", skipping`);
    return 0;
  }

  const batch = db.batch();
  for (const question of questions) {
    batch.set(db.collection("questions").doc(), {
      categoryId,
      ownerId: null,
      questionText: question.questionText,
      options: question.options,
      correctAnswerIndex: question.correctAnswerIndex,
      difficulty: question.difficulty,
      source: "llm",
      language,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  batch.update(db.collection("categories").doc(categoryId), {
    questionCount: FieldValue.increment(questions.length),
  });
  await batch.commit();
  return questions.length;
}

async function seedAll(): Promise<void> {
  await ensureCategoryGroups();

  for (const category of CATEGORIES) {
    await ensureCategory(category);

    const arCount = await seedLanguagePool(category.id, category.name, "ar", PREGENERATED_QUESTIONS[category.id]);
    const enCount = await seedLanguagePool(category.id, category.name, "en", PREGENERATED_QUESTIONS_EN[category.id]);

    console.log(`  ${category.name}: +${arCount} Arabic, +${enCount} English`);
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
 * recreated, but re-running DOES add another copy of this same Arabic +
 * English starter pool per category each time — run it once rather than
 * repeatedly.
 */
