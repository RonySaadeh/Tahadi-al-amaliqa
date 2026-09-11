import { HttpsError, onCall } from "firebase-functions/v2/https";
import { db, FieldValue } from "../lib/admin";
import { FriendshipDoc, FriendshipStatus, NotificationDoc, UserDoc } from "../lib/types";

/** Deterministic doc id for a friendship/request between two users,
 * independent of who sent it — same trick `leaderboardPairings` uses (see
 * `FirestorePaths.pairingId` on the client), which is what makes a
 * duplicate friend request or duplicate friendship structurally
 * impossible: there's only ever one document for a given pair. */
function friendshipId(uidA: string, uidB: string): string {
  const [a, b] = [uidA, uidB].sort();
  return `${a}_${b}`;
}

/**
 * Sends a friend request, or re-sends one after a previous decline.
 * Refuses outright if a request between this pair is already pending or
 * already accepted — that plus the deterministic doc id above is the whole
 * duplicate-prevention story.
 */
export const sendFriendRequest = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");

  const { toUserId } = request.data as { toUserId?: unknown };
  if (typeof toUserId !== "string" || toUserId.length === 0) {
    throw new HttpsError("invalid-argument", "toUserId is required.");
  }
  if (toUserId === uid) {
    throw new HttpsError("invalid-argument", "You can't send yourself a friend request.");
  }

  const friendshipRef = db.collection("friendships").doc(friendshipId(uid, toUserId));

  await db.runTransaction(async (tx) => {
    const [friendshipSnap, fromUserSnap, toUserSnap] = await Promise.all([
      tx.get(friendshipRef),
      tx.get(db.collection("users").doc(uid)),
      tx.get(db.collection("users").doc(toUserId)),
    ]);
    if (!toUserSnap.exists) throw new HttpsError("not-found", "User not found.");

    const existing = friendshipSnap.data() as FriendshipDoc | undefined;
    if (existing?.status === "pending") {
      throw new HttpsError("already-exists", "A friend request is already pending between you two.");
    }
    if (existing?.status === "accepted") {
      throw new HttpsError("already-exists", "You're already friends.");
    }

    const [uidA, uidB] = [uid, toUserId].sort();
    const fromDisplayName: string = (fromUserSnap.data() as UserDoc | undefined)?.displayName ?? "";

    tx.set(friendshipRef, {
      uidA,
      uidB,
      fromUserId: uid,
      fromDisplayName,
      toUserId,
      status: "pending" satisfies FriendshipStatus,
      createdAt: FieldValue.serverTimestamp(),
      respondedAt: null,
    } satisfies FriendshipDoc);

    tx.set(db.collection("notifications").doc(), {
      userId: toUserId,
      type: "friend_request",
      fromUserId: uid,
      fromDisplayName,
      relatedId: friendshipRef.id,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    } satisfies NotificationDoc);
  });

  return { success: true };
});

/**
 * Accepts or declines a pending friend request. `otherUserId` is the other
 * person in the pair, not an opaque request id — the friendship doc's id is
 * derived the same deterministic way `sendFriendRequest` created it, so the
 * caller never needs a separate id for it.
 */
export const respondToFriendRequest = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");

  const { otherUserId, accept } = request.data as { otherUserId?: unknown; accept?: unknown };
  if (typeof otherUserId !== "string" || otherUserId.length === 0) {
    throw new HttpsError("invalid-argument", "otherUserId is required.");
  }
  if (typeof accept !== "boolean") {
    throw new HttpsError("invalid-argument", "accept must be a boolean.");
  }

  const friendshipRef = db.collection("friendships").doc(friendshipId(uid, otherUserId));
  const friendshipSnap = await friendshipRef.get();
  if (!friendshipSnap.exists) throw new HttpsError("not-found", "Friend request not found.");
  const friendship = friendshipSnap.data() as FriendshipDoc;

  if (friendship.toUserId !== uid) {
    throw new HttpsError("permission-denied", "This friend request isn't addressed to you.");
  }
  if (friendship.status !== "pending") {
    throw new HttpsError("failed-precondition", "This friend request was already responded to.");
  }

  await friendshipRef.update({
    status: (accept ? "accepted" : "declined") satisfies FriendshipStatus,
    respondedAt: FieldValue.serverTimestamp(),
  });

  return { success: true };
});
