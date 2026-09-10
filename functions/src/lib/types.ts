/**
 * Shared types mirroring `lib/core/constants/app_enums.dart` and the
 * Firestore document shapes. Keep the string literal values identical to
 * the Dart enum names — the client parses these directly.
 */

export type DuelStatus = "pending" | "active" | "completed" | "cancelled";
export type RoundStatus = "active" | "resolved";
export type QuestionDifficulty = "easy" | "medium" | "hard";
export type QuestionSource = "api" | "llm" | "user";
export type DuelInviteStatus = "pending" | "accepted" | "declined" | "expired";

export interface QuestionDoc {
  categoryId: string;
  ownerId: string | null;
  questionText: string;
  options: string[]; // always length 4
  correctAnswerIndex: number; // 0-3
  difficulty: QuestionDifficulty;
  source: QuestionSource;
  language: string; // 'ar' | 'en'
  createdAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
}

export interface DuelDoc {
  player1Id: string;
  player2Id: string;
  player1DisplayName: string;
  player2DisplayName: string;
  categoryId: string;
  categoryName: string;
  language: string; // 'ar' | 'en' — fixed for the whole duel so both rounds match
  isHomeTurfDuel: boolean;
  homeTurfOwnerId: string | null;
  status: DuelStatus;
  player1Score: number;
  player2Score: number;
  currentRound: number;
  totalRounds: number;
  /** Every questionId used so far this duel (all rounds, not just the
   * latest), so `pickNextQuestion` can avoid repeating one — see
   * `resolveDuel.ts`. */
  usedQuestionIds: string[];
  winnerId: string | null;
  eloChange: Record<string, number>;
  createdAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  startedAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp | null;
  completedAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp | null;
}

export interface RoundDoc {
  roundNumber: number;
  questionId: string;
  questionText: string;
  options: string[];
  difficulty: QuestionDifficulty;
  status: RoundStatus;
  correctAnswerIndex: number | null; // null until resolved
  playerAnswers: Record<string, number>; // uid -> selected index, only once resolved
  pointsAwarded: Record<string, number>; // uid -> points, only once resolved
  startedAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
}

export interface UserDoc {
  displayName: string;
  email: string;
  photoUrl: string | null;
  elo: number;
  wins: number;
  losses: number;
  currentStreak: number;
  bestStreak: number;
  ownedCategoryIds: string[];
  createdAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  locale: string;
}
