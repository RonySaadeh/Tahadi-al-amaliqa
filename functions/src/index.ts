/**
 * Every Cloud Function the app deploys, re-exported from one place so
 * `firebase deploy --only functions` and the emulator can find them all.
 * The actual logic lives in the files under scoring/, questions/, and
 * matchmaking/ — this file is intentionally just a list.
 */
export { submitAnswer } from "./scoring/submitAnswer";
export { expireStaleRounds } from "./scoring/expireStaleRounds";
export { heartbeat, forfeitDuel } from "./scoring/presence";

export { createHomeTurfCategory, addHomeTurfQuestion } from "./questions/homeTurf";

export { sendDuelChallenge, respondToDuelChallenge } from "./matchmaking/duelChallenges";
export { joinOpenLobby, leaveOpenLobby } from "./matchmaking/openLobby";

export { sendFriendRequest, respondToFriendRequest } from "./social/friends";
