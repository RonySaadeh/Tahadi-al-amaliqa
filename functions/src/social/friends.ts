import { HttpsError, onCall } from "firebase-functions/v2/https";
import { db, FieldValue } from "../lib/admin";
import { FriendshipDoc, FriendshipStatus, NotificationDoc, UserDoc } from "../lib/types";
import { sendPushToUser } from "../lib/push";
import { pushCopyFor } from "../lib/pushCopy";

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

  const { fromDisplayName, toUserLocale } = await db.runTransaction(async (tx) => {
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
      participantIds: [uidA, uidB],
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

    return { fromDisplayName, toUserLocale: (toUserSnap.data() as UserDoc).locale };
  });

  const copy = pushCopyFor(toUserLocale);
  await sendPushToUser(toUserId, {
    title: copy.friendRequestTitle,
    body: copy.friendRequestBody(fromDisplayName),
    data: { type: "friend_request", relatedId: friendshipRef.id },
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

  // The inbox notification (with its Accept/Decline buttons) has done its
  // job the moment this request is responded to — `firestore.rules` blocks
  // the client from deleting it itself, and left in place it would let the
  // recipient "respond" to an already-resolved request again from a stale
  // notifications list.
  const [notificationsSnap, accepterSnap, senderSnap] = await Promise.all([
    db
      .collection("notifications")
      .where("relatedId", "==", friendshipRef.id)
      .where("type", "==", "friend_request" satisfies NotificationDoc["type"])
      .get(),
    // Only needed on accept (for the "X accepted your request" push back to
    // the original sender) — fetched unconditionally anyway since it's one
    // extra doc read either way and keeps this simpler than branching.
    db.collection("users").doc(uid).get(),
    db.collection("users").doc(friendship.fromUserId).get(),
  ]);

  await Promise.all([
    friendshipRef.update({
      status: (accept ? "accepted" : "declined") satisfies FriendshipStatus,
      respondedAt: FieldValue.serverTimestamp(),
    }),
    ...notificationsSnap.docs.map((doc) => doc.ref.delete()),
  ]);

  // Only the sender hears back, and only on accept — a decline notification
  // would just be an awkward "you got rejected" push for no actionable
  // benefit, the same reason most social apps skip it.
  if (accept) {
    const accepterDisplayName = (accepterSnap.data() as UserDoc | undefined)?.displayName ?? "";
    const senderLocale = (senderSnap.data() as UserDoc | undefined)?.locale;

    await db.collection("notifications").add({
      userId: friendship.fromUserId,
      type: "friend_request_accepted",
      fromUserId: uid,
      fromDisplayName: accepterDisplayName,
      relatedId: friendshipRef.id,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    } satisfies NotificationDoc);

    const copy = pushCopyFor(senderLocale);
    await sendPushToUser(friendship.fromUserId, {
      title: copy.friendRequestAcceptedTitle,
      body: copy.friendRequestAcceptedBody(accepterDisplayName),
      data: { type: "friend_request_accepted", relatedId: friendshipRef.id },
    });
  }

  return { success: true };
});
