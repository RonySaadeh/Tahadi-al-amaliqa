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
export type FriendshipStatus = "pending" | "accepted" | "declined";
export type NotificationType = "friend_request" | "duel_challenge";

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
  /** `[player1Id, player2Id]` — lets the client find "my duels" with a
   * single `array-contains` query instead of running the `player1Id`/
   * `player2Id` queries separately. Firestore rejects a `list` query
   * against a rule that ORs two different `resource.data` fields (it can't
   * prove every possible result satisfies a field the query itself didn't
   * filter on), so `firestore.rules`' `duels` read rule checks membership
   * in this array instead — see the same note on `FriendshipDoc`. */
  participantIds: string[];
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
  /** Last time each player's client called the `heartbeat` callable while
   * this duel was active — see `scoring/presence.ts`. Absent/undefined until
   * their first heartbeat; never set on a duel that finished before this
   * feature shipped. */
  player1LastSeenAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp | null;
  player2LastSeenAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp | null;
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
  /** Stamped by the client itself (see `firestore.rules`'s narrow
   * presence-only update path), not a Cloud Function — a lightweight
   * heartbeat, not a trust-sensitive field. Absent until a client's first
   * heartbeat. "Online" is derived from this (recent enough), not stored as
   * its own boolean, since Firestore has no `onDisconnect` to keep a boolean
   * honest. */
  lastActiveAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp | null;
}

/** One doc per unordered pair of users, id = sorted `${uidA}_${uidB}` (see
 * `friendshipId` in `social/friends.ts`) — the same trick
 * `leaderboardPairings` uses, so a duplicate request or duplicate friendship
 * between the same two people is structurally impossible: there is only
 * ever one document for that pair. */
export interface FriendshipDoc {
  uidA: string;
  uidB: string;
  /** `[uidA, uidB]` — see the identical field on `DuelDoc` above for why:
   * `firestore.rules`' `friendships` read rule needs a single array field
   * to check membership against, because a `list` query can't be proven
   * safe against a rule that ORs two separate `resource.data` fields. */
  participantIds: string[];
  fromUserId: string;
  fromDisplayName: string;
  toUserId: string;
  status: FriendshipStatus;
  createdAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  respondedAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp | null;
}

/** A user's in-app inbox entry. Created only by Cloud Functions as a side
 * effect of the real action (`sendFriendRequest`, `sendDuelChallenge`);
 * `read` is the one field a client may update directly — see
 * `firestore.rules`. */
export interface NotificationDoc {
  userId: string;
  type: NotificationType;
  fromUserId: string;
  fromDisplayName: string;
  /** The `friendships` or `duelInvites` doc id this notification is about,
   * so its Accept/Decline buttons can act on the real thing directly. */
  relatedId: string;
  read: boolean;
  createdAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
}
