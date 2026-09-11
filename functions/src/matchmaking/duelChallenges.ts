import { HttpsError, onCall } from "firebase-functions/v2/https";
import { db, FieldValue } from "../lib/admin";
import { DuelInviteStatus, NotificationDoc } from "../lib/types";
import { createDuelForPlayers } from "./createDuel";

/** Player A challenging a specific friend (as opposed to the open-lobby
 * quick-match flow in `openLobby.ts`). Just creates the invite — the duel
 * itself is only created once the other player accepts. */
export const sendDuelChallenge = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");

  const { toUserId, categoryId } = request.data as { toUserId?: unknown; categoryId?: unknown };
  if (typeof toUserId !== "string" || toUserId.length === 0) {
    throw new HttpsError("invalid-argument", "toUserId is required.");
  }
  if (toUserId === uid) {
    throw new HttpsError("invalid-argument", "You can't challenge yourself.");
  }
  if (typeof categoryId !== "string" || categoryId.length === 0) {
    throw new HttpsError("invalid-argument", "categoryId is required.");
  }

  const [fromUserSnap, categorySnap] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("categories").doc(categoryId).get(),
  ]);
  if (!categorySnap.exists) throw new HttpsError("not-found", "Category not found.");

  // Picked in the sender's language, since if this invite is accepted,
  // `createDuelForPlayers` fixes the duel's question language to the
  // sender's (player1) locale too — keeps the invite's category label
  // consistent with the language the duel will actually play in.
  const category = categorySnap.data()!;
  const senderLocale: string = fromUserSnap.data()?.locale ?? "en";
  const categoryName: string =
    senderLocale === "en" && category.nameEn ? category.nameEn : (category.name ?? "");

  const inviteRef = db.collection("duelInvites").doc();
  const fromDisplayName: string = fromUserSnap.data()?.displayName ?? "";
  const batch = db.batch();
  batch.set(inviteRef, {
    fromUserId: uid,
    fromDisplayName,
    toUserId,
    categoryId,
    categoryName,
    status: "pending" satisfies DuelInviteStatus,
    createdAt: FieldValue.serverTimestamp(),
  });
  // Same notification inbox `sendFriendRequest` writes to — see
  // `social/friends.ts` and `firestore.rules`.
  batch.set(db.collection("notifications").doc(), {
    userId: toUserId,
    type: "duel_challenge",
    fromUserId: uid,
    fromDisplayName,
    relatedId: inviteRef.id,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  } satisfies NotificationDoc);
  await batch.commit();

  return { success: true };
});

/** The invited player accepting or declining. Accepting is what actually
 * creates the duel (via `createDuelForPlayers`) and returns its id so the
 * client can navigate straight into the live duel screen. */
export const respondToDuelChallenge = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");

  const { inviteId, accept } = request.data as { inviteId?: unknown; accept?: unknown };
  if (typeof inviteId !== "string" || inviteId.length === 0) {
    throw new HttpsError("invalid-argument", "inviteId is required.");
  }
  if (typeof accept !== "boolean") {
    throw new HttpsError("invalid-argument", "accept must be a boolean.");
  }

  const inviteRef = db.collection("duelInvites").doc(inviteId);
  const inviteSnap = await inviteRef.get();
  if (!inviteSnap.exists) throw new HttpsError("not-found", "Invite not found.");
  const invite = inviteSnap.data()!;

  if (invite.toUserId !== uid) {
    throw new HttpsError("permission-denied", "This invite isn't addressed to you.");
  }
  if (invite.status !== "pending") {
    throw new HttpsError("failed-precondition", "This invite was already responded to.");
  }

  if (!accept) {
    await inviteRef.update({ status: "declined" satisfies DuelInviteStatus });
    return { success: true };
  }

  const duelId = await createDuelForPlayers(invite.fromUserId, invite.toUserId, invite.categoryId);
  await inviteRef.update({ status: "accepted" satisfies DuelInviteStatus });
  return { success: true, duelId };
});
