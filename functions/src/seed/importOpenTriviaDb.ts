/**
 * One-off admin script: imports questions from the free Open Trivia
 * Database (https://opentdb.com) into a set of global (ownerId: null)
 * Firestore categories, so the app has something playable before anyone's
 * written a home-turf category by hand.
 *
 * This is a SCRIPT, not a deployed Cloud Function — it's meant to be run
 * once (or re-run occasionally to top up) by whoever administers the
 * Firebase project, not triggered by players. See the "Running this" note
 * at the bottom of the file.
 *
 * Why a separate file from `questions/generateQuestions.ts`: that function
 * calls the Claude API and is scoped to a category's own owner. This
 * script has no owner (categories it creates have `ownerId: null`) and
 * pulls from a different, non-AI source — English trivia questions that
 * already exist rather than ones written on demand. Both end up writing
 * the same `QuestionDoc` shape (see `lib/types.ts`), just tagged with a
 * different `source`.
 */
import { db, FieldValue } from "../lib/admin";
import { QuestionDifficulty } from "../lib/types";

/** Open Trivia DB category id -> the category we create for it in this
 * app. English-only content stays in its own categories rather than mixed
 * into the Arabic ones, so a duel never switches languages mid-match. */
const CATEGORY_MAP: Record<number, { name: string; description: string }> = {
  9: { name: "General Knowledge", description: "Open Trivia DB — general knowledge" },
  11: { name: "Film", description: "Open Trivia DB — movies" },
  12: { name: "Music", description: "Open Trivia DB — music" },
  14: { name: "Television", description: "Open Trivia DB — TV shows" },
  15: { name: "Video Games", description: "Open Trivia DB — video games" },
  17: { name: "Science & Nature", description: "Open Trivia DB — science & nature" },
  21: { name: "Sports", description: "Open Trivia DB — sports" },
  22: { name: "Geography", description: "Open Trivia DB — geography" },
  23: { name: "History", description: "Open Trivia DB — history" },
  27: { name: "Animals", description: "Open Trivia DB — animals" },
  31: { name: "Anime & Manga", description: "Open Trivia DB — anime & manga" },
};

const DIFFICULTIES: QuestionDifficulty[] = ["easy", "medium", "hard"];

/** OpenTDB asks for at least 5 seconds between requests from the same IP —
 * see https://opentdb.com/api_config.php. Anything shorter risks an HTTP
 * 429 mid-import. */
const REQUEST_DELAY_MS = 5500;

interface OpenTdbResponse {
  response_code: number;
  results: Array<{
    category: string;
    difficulty: string;
    question: string;
    correct_answer: string;
    incorrect_answers: string[];
  }>;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function decodeBase64(value: string): string {
  return Buffer.from(value, "base64").toString("utf-8");
}

/** Deterministic id so re-running the script updates the same category
 * doc instead of creating duplicates. */
function categoryDocId(openTdbId: number): string {
  return `otdb-${openTdbId}`;
}

async function ensureCategory(openTdbId: number): Promise<string> {
  const info = CATEGORY_MAP[openTdbId];
  const docId = categoryDocId(openTdbId);
  const ref = db.collection("categories").doc(docId);
  const snap = await ref.get();

  if (!snap.exists) {
    await ref.set({
      name: info.name,
      description: info.description,
      ownerId: null,
      ownerDisplayName: null,
      questionCount: 0,
      createdAt: FieldValue.serverTimestamp(),
    });
    console.log(`Created category "${info.name}" (${docId})`);
  }

  return docId;
}

async function fetchQuestions(
  openTdbId: number,
  difficulty: QuestionDifficulty,
  amount: number,
): Promise<OpenTdbResponse["results"]> {
  const url = `https://opentdb.com/api.php?amount=${amount}&category=${openTdbId}&difficulty=${difficulty}&type=multiple&encode=base64`;
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`OpenTDB request failed: HTTP ${response.status}`);
  }

  const data = (await response.json()) as OpenTdbResponse;
  // response_code 1 just means "fewer than `amount` available for this
  // category/difficulty" — not fatal, we still use whatever came back.
  if (data.response_code !== 0 && data.response_code !== 1) {
    throw new Error(`OpenTDB returned response_code ${data.response_code} for category ${openTdbId}`);
  }
  return data.results;
}

/** Combines OpenTDB's separate correct/incorrect fields into a shuffled
 * 4-option array plus the resulting correct index — this app's schema
 * (and every duel round UI) expects exactly that shape. */
function toShuffledOptions(correctAnswer: string, incorrectAnswers: string[]): {
  options: string[];
  correctAnswerIndex: number;
} {
  const options = [correctAnswer, ...incorrectAnswers];
  for (let i = options.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [options[i], options[j]] = [options[j], options[i]];
  }
  return { options, correctAnswerIndex: options.indexOf(correctAnswer) };
}

/**
 * Imports up to `amountPerDifficulty` questions (per easy/medium/hard) for
 * every category in [CATEGORY_MAP]. Total requests = categories × 3, each
 * spaced [REQUEST_DELAY_MS] apart — with all 11 default categories that's
 * ~33 requests, a little over 3 minutes end to end.
 */
async function importAll(amountPerDifficulty = 15): Promise<void> {
  const openTdbIds = Object.keys(CATEGORY_MAP).map(Number);

  for (const openTdbId of openTdbIds) {
    const categoryId = await ensureCategory(openTdbId);
    let importedForCategory = 0;

    for (const difficulty of DIFFICULTIES) {
      await sleep(REQUEST_DELAY_MS);

      const results = await fetchQuestions(openTdbId, difficulty, amountPerDifficulty);
      if (results.length === 0) {
        console.log(`  ${CATEGORY_MAP[openTdbId].name} / ${difficulty}: nothing returned, skipping`);
        continue;
      }

      const batch = db.batch();
      for (const raw of results) {
        const questionText = decodeBase64(raw.question);
        const correctAnswer = decodeBase64(raw.correct_answer);
        const incorrectAnswers = raw.incorrect_answers.map(decodeBase64);
        const { options, correctAnswerIndex } = toShuffledOptions(correctAnswer, incorrectAnswers);

        batch.set(db.collection("questions").doc(), {
          categoryId,
          ownerId: null,
          questionText,
          options,
          correctAnswerIndex,
          difficulty,
          source: "api",
          language: "en",
          createdAt: FieldValue.serverTimestamp(),
        });
      }
      batch.update(db.collection("categories").doc(categoryId), {
        questionCount: FieldValue.increment(results.length),
      });
      await batch.commit();

      importedForCategory += results.length;
      console.log(`  ${CATEGORY_MAP[openTdbId].name} / ${difficulty}: +${results.length} questions`);
    }

    console.log(`${CATEGORY_MAP[openTdbId].name}: ${importedForCategory} questions total this run`);
  }

  console.log("Done.");
}

// Only runs when this file is executed directly (`node lib/seed/importOpenTriviaDb.js`),
// never when imported — see the "Running this" note below.
if (require.main === module) {
  const amountArg = Number(process.argv[2]);
  const amountPerDifficulty = Number.isInteger(amountArg) && amountArg > 0 ? amountArg : 15;

  importAll(amountPerDifficulty)
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

/**
 * Running this:
 *
 * Against the local emulator (safe, free, resets when the emulator stops):
 *   firebase emulators:start --only firestore
 *   # in another terminal:
 *   cd functions && npm run build
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 GCLOUD_PROJECT=<your-project-id> \
 *     node lib/seed/importOpenTriviaDb.js
 *
 * Against your real Firebase project (writes real data, still free — this
 * only calls OpenTDB and Firestore, no paid API involved):
 *   gcloud auth application-default login   # once, if you haven't
 *   cd functions && npm run build
 *   GOOGLE_APPLICATION_CREDENTIALS=<path-to-a-service-account-key.json> \
 *     node lib/seed/importOpenTriviaDb.js
 *
 * Optional first argument overrides how many questions per
 * category/difficulty to request (default 15, max ~50 per OpenTDB call):
 *   node lib/seed/importOpenTriviaDb.js 25
 *
 * Safe to re-run — categories use a deterministic id (`otdb-<id>`) so
 * re-running won't duplicate categories, though it WILL add another batch
 * of questions each time (OpenTDB has no "since last run" filter).
 */
