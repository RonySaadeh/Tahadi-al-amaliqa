/**
 * One-off admin script: creates every group + category in
 * `categoryTaxonomy.ts` as a global (`ownerId: null`) Firestore category,
 * then generates a batch of real questions for each via the same Claude
 * logic the in-app "Generate with AI" button uses
 * (`questions/generateQuestions.ts`'s `generateQuestionsCore`).
 *
 * Like `importOpenTriviaDb.ts`, this is a SCRIPT, not a deployed Cloud
 * Function — see the "Running this" note at the bottom.
 *
 * Cost/time reality check: with the defaults below (57 categories × 3
 * difficulties × 8 questions = ~1,368 questions), this makes 171 Claude
 * API calls. Expect it to take a while and to cost a small but real amount
 * of Claude API usage — this is not a free operation the way the OpenTDB
 * importer is. Safe to interrupt and re-run: categories use deterministic
 * ids, and it always just adds another batch rather than erroring on
 * existing content.
 */
import { CATEGORIES } from "./categoryTaxonomy";
import { generateQuestionsCore, resolveClaudeCredentials } from "../questions/generateQuestions";
import { QuestionDifficulty } from "../lib/types";
import { ensureCategory, ensureCategoryGroups } from "./taxonomyFirestore";

const DIFFICULTIES: QuestionDifficulty[] = ["easy", "medium", "hard"];

/** A short pause between Claude calls — not required by the Anthropic API
 * the way OpenTDB requires 5s, but spacing requests out avoids bursting
 * past your account's requests-per-minute limit when running unattended
 * across hundreds of calls. */
const REQUEST_DELAY_MS = 1500;

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function seedAll(questionsPerDifficulty: number): Promise<void> {
  const { apiKey, model } = resolveClaudeCredentials();
  if (!apiKey) {
    throw new Error(
      "ANTHROPIC_API_KEY is not set in this process's environment — export it before running this script. " +
        "If you don't want to deal with an API key at all, run `npm run seed:pregenerated` instead — it uses " +
        "a hand-written starter question pool and needs no Claude API access.",
    );
  }

  await ensureCategoryGroups();

  for (const category of CATEGORIES) {
    await ensureCategory(category);
    let totalForCategory = 0;

    for (const difficulty of DIFFICULTIES) {
      await sleep(REQUEST_DELAY_MS);
      try {
        const created = await generateQuestionsCore({
          categoryId: category.id,
          ownerId: null,
          topic: category.topic,
          difficulty,
          count: questionsPerDifficulty,
          language: category.language,
          apiKey,
          model,
        });
        totalForCategory += created;
        console.log(`  ${category.name} / ${difficulty}: +${created} questions`);
      } catch (error) {
        // Keep going — one bad category/difficulty shouldn't abort a run
        // that's already made real API calls for the others.
        console.error(`  ${category.name} / ${difficulty}: FAILED —`, error);
      }
    }

    console.log(`${category.name}: ${totalForCategory} questions this run`);
  }

  console.log("Done.");
}

if (require.main === module) {
  const amountArg = Number(process.argv[2]);
  const questionsPerDifficulty = Number.isInteger(amountArg) && amountArg > 0 ? amountArg : 8;

  seedAll(questionsPerDifficulty)
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

/**
 * Running this:
 *
 * Needs `ANTHROPIC_API_KEY` as a plain environment variable (this reads it
 * the same way the deployed function does via `defineSecret`, but a local
 * script isn't handed Secret Manager values automatically — export it
 * yourself) plus Firestore admin credentials, same as
 * `importOpenTriviaDb.ts`:
 *
 *   cd functions && npm run build
 *   GOOGLE_APPLICATION_CREDENTIALS=<path-to-a-service-account-key.json> \
 *     ANTHROPIC_API_KEY=sk-ant-... \
 *     node lib/seed/seedCategoryTaxonomy.js
 *
 * Against the local emulator instead of your real project:
 *   firebase emulators:start --only firestore
 *   # in another terminal:
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 GCLOUD_PROJECT=<your-project-id> \
 *     ANTHROPIC_API_KEY=sk-ant-... \
 *     node lib/seed/seedCategoryTaxonomy.js
 *
 * Optional first argument overrides how many questions per
 * category/difficulty to generate (default 8, so ~24 questions/category):
 *   node lib/seed/seedCategoryTaxonomy.js 15
 *
 * Want more/different categories later? Edit `categoryTaxonomy.ts` and
 * re-run — existing categories are skipped (by id), only new ones get
 * created, and every category gets another batch of questions each run.
 */
