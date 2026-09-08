import Anthropic from "@anthropic-ai/sdk";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import { db, FieldValue } from "../lib/admin";
import { DEFAULT_CLAUDE_MODEL } from "../lib/constants";
import { QuestionDifficulty } from "../lib/types";

/**
 * Generates a batch of trivia questions for a category by calling the
 * Claude API, validating the JSON it returns, and writing the well-formed
 * ones to Firestore.
 *
 * The client NEVER talks to Claude directly — `ANTHROPIC_API_KEY` only
 * exists in this function's environment (see SETUP.md for how to set it
 * with `firebase functions:secrets:set`). This is also the ONE place that
 * decides what counts as a validly-shaped question, so if generated
 * questions look wrong or are getting silently dropped, this file is where
 * to look.
 *
 * [generateQuestionsCore] is the actual logic, callable from anywhere in
 * this codebase that already trusts its caller (the `generateQuestions`
 * callable below, which checks the requester owns the category; and
 * `seed/seedCategoryTaxonomy.ts`, an admin script that has no "owner" to
 * check because it's populating system categories). Keeping the core
 * separate from the `onCall` wrapper means both call sites share the exact
 * same prompt, validation, and write logic instead of two copies drifting
 * apart.
 */
const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");
const claudeModel = defineString("CLAUDE_MODEL", { default: DEFAULT_CLAUDE_MODEL });

const VALID_DIFFICULTIES: QuestionDifficulty[] = ["easy", "medium", "hard"];

interface RawGeneratedQuestion {
  questionText?: unknown;
  options?: unknown;
  correctAnswerIndex?: unknown;
}

/** Returns a clean question object, or null if the shape is invalid. */
function validateGeneratedQuestion(
  raw: RawGeneratedQuestion,
): { questionText: string; options: string[]; correctAnswerIndex: number } | null {
  if (typeof raw.questionText !== "string" || raw.questionText.trim().length === 0) return null;
  if (!Array.isArray(raw.options) || raw.options.length !== 4) return null;
  if (!raw.options.every((option) => typeof option === "string" && option.trim().length > 0)) return null;
  if (
    typeof raw.correctAnswerIndex !== "number" ||
    !Number.isInteger(raw.correctAnswerIndex) ||
    raw.correctAnswerIndex < 0 ||
    raw.correctAnswerIndex > 3
  ) {
    return null;
  }

  return {
    questionText: raw.questionText.trim(),
    options: raw.options.map((option) => (option as string).trim()),
    correctAnswerIndex: raw.correctAnswerIndex,
  };
}

function buildPrompt(topic: string, difficulty: string, count: number, language: string): string {
  const languageName = language === "ar" ? "Arabic" : "English";
  return `Generate exactly ${count} multiple-choice trivia questions about "${topic}" at ${difficulty} difficulty, written in ${languageName}.

Respond with ONLY a JSON array (no prose, no markdown fences) where each element has exactly this shape:
{"questionText": string, "options": [string, string, string, string], "correctAnswerIndex": 0|1|2|3}

Rules:
- Exactly 4 options per question, all plausible, only one correct.
- correctAnswerIndex is the 0-based index of the correct option within "options".
- Questions must be factually accurate and unambiguous.
- Vary which index holds the correct answer across questions.`;
}

/** Claude sometimes wraps JSON in prose or code fences despite instructions
 * not to — this pulls out the first top-level `[...]` array so parsing
 * doesn't fail on stray text around it. */
function extractJsonArray(text: string): string {
  const start = text.indexOf("[");
  const end = text.lastIndexOf("]");
  if (start === -1 || end === -1 || end < start) return text;
  return text.slice(start, end + 1);
}

export interface GenerateQuestionsParams {
  categoryId: string;
  ownerId: string | null;
  topic: string;
  difficulty: QuestionDifficulty;
  count: number;
  language: string;
  apiKey: string;
  model: string;
}

/** Calls Claude, validates its response, and writes the valid questions +
 * an updated `questionCount` to Firestore. Returns how many were kept —
 * always less than or equal to `count` since malformed ones are dropped
 * rather than retried. */
export async function generateQuestionsCore(params: GenerateQuestionsParams): Promise<number> {
  const anthropic = new Anthropic({ apiKey: params.apiKey });
  const response = await anthropic.messages.create({
    model: params.model,
    max_tokens: 4096,
    messages: [{ role: "user", content: buildPrompt(params.topic, params.difficulty, params.count, params.language) }],
  });

  const textBlock = response.content.find((block) => block.type === "text");
  if (!textBlock || textBlock.type !== "text") {
    throw new Error("Claude returned no text content.");
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(extractJsonArray(textBlock.text));
  } catch {
    throw new Error("Claude's response was not valid JSON.");
  }
  if (!Array.isArray(parsed)) {
    throw new Error("Claude's response was not a JSON array.");
  }

  const validQuestions = (parsed as RawGeneratedQuestion[])
    .map(validateGeneratedQuestion)
    .filter((q): q is NonNullable<ReturnType<typeof validateGeneratedQuestion>> => q !== null);

  const batch = db.batch();
  for (const question of validQuestions) {
    const ref = db.collection("questions").doc();
    batch.set(ref, {
      categoryId: params.categoryId,
      ownerId: params.ownerId,
      questionText: question.questionText,
      options: question.options,
      correctAnswerIndex: question.correctAnswerIndex,
      difficulty: params.difficulty,
      source: "llm",
      language: params.language,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  if (validQuestions.length > 0) {
    batch.update(db.collection("categories").doc(params.categoryId), {
      questionCount: FieldValue.increment(validQuestions.length),
    });
  }
  await batch.commit();

  return validQuestions.length;
}

export const generateQuestions = onCall({ secrets: [anthropicApiKey] }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const { categoryId, topic, difficulty, count, language } = request.data as {
    categoryId?: unknown;
    topic?: unknown;
    difficulty?: unknown;
    count?: unknown;
    language?: unknown;
  };

  if (typeof categoryId !== "string" || categoryId.length === 0) {
    throw new HttpsError("invalid-argument", "categoryId is required.");
  }
  if (typeof topic !== "string" || topic.trim().length === 0) {
    throw new HttpsError("invalid-argument", "topic is required.");
  }
  if (typeof difficulty !== "string" || !VALID_DIFFICULTIES.includes(difficulty as QuestionDifficulty)) {
    throw new HttpsError("invalid-argument", "difficulty must be easy, medium, or hard.");
  }
  const requestedCount = typeof count === "number" ? Math.min(Math.max(Math.trunc(count), 1), 20) : 10;
  const resolvedLanguage = typeof language === "string" && language.length > 0 ? language : "ar";

  const categorySnap = await db.collection("categories").doc(categoryId).get();
  if (!categorySnap.exists) {
    throw new HttpsError("not-found", "Category not found.");
  }
  if (categorySnap.data()?.ownerId !== uid) {
    throw new HttpsError("permission-denied", "You can only generate questions for your own category.");
  }

  try {
    const questionsCreated = await generateQuestionsCore({
      categoryId,
      ownerId: uid,
      topic,
      difficulty: difficulty as QuestionDifficulty,
      count: requestedCount,
      language: resolvedLanguage,
      apiKey: anthropicApiKey.value(),
      model: claudeModel.value(),
    });
    return { questionsCreated };
  } catch (error) {
    throw new HttpsError("internal", error instanceof Error ? error.message : "Question generation failed.");
  }
});

/** Exposed for the seed script, which needs the resolved secret/param
 * values but doesn't run inside an `onCall` request context. */
export function resolveClaudeCredentials(): { apiKey: string; model: string } {
  return { apiKey: anthropicApiKey.value(), model: claudeModel.value() };
}
