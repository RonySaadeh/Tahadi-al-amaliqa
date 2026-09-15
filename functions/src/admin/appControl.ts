import { HttpsError, onCall } from "firebase-functions/v2/https";
import { db, FieldValue, Timestamp } from "../lib/admin";
import { AppControlDoc, NotificationDoc, UserDoc } from "../lib/types";
import { GLOBAL_ANNOUNCEMENTS_TOPIC, sendPushToTopic } from "../lib/push";

const appControlRef = db.collection("appControl").doc("status");

/**
 * Every callable in this file re-checks `isAdmin` itself rather than
 * trusting `firestore.rules` — this document is client-write-blocked
 * entirely (see `firestore.rules`), so these callables are the *only* write
 * path, and each one has to prove the caller is allowed to use it, the same
 * way `createHomeTurfCategory` proves category ownership before writing.
 */
async function requireAdmin(uid: string | undefined): Promise<string> {
  if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");
  const userSnap = await db.collection("users").doc(uid).get();
  const user = userSnap.data() as UserDoc | undefined;
  if (!user?.isAdmin) {
    throw new HttpsError("permission-denied", "You don't have access to App Control.");
  }
  return uid;
}

export const setMaintenanceMode = onCall(async (request) => {
  const uid = await requireAdmin(request.auth?.uid);
  const { enabled, message } = request.data as { enabled?: unknown; message?: unknown };
  if (typeof enabled !== "boolean") throw new HttpsError("invalid-argument", "enabled must be a boolean.");
  if (typeof message !== "string") throw new HttpsError("invalid-argument", "message must be a string.");

  await appControlRef.set(
    {
      maintenance: { enabled, message: message.trim().slice(0, 500) },
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    } satisfies Partial<AppControlDoc>,
    { merge: true },
  );
  return { success: true };
});

export const setForceUpdate = onCall(async (request) => {
  const uid = await requireAdmin(request.auth?.uid);
  const { enabled, minVersion, message, url } = request.data as {
    enabled?: unknown;
    minVersion?: unknown;
    message?: unknown;
    url?: unknown;
  };
  if (typeof enabled !== "boolean") throw new HttpsError("invalid-argument", "enabled must be a boolean.");
  if (typeof minVersion !== "string") throw new HttpsError("invalid-argument", "minVersion must be a string.");
  if (typeof message !== "string") throw new HttpsError("invalid-argument", "message must be a string.");
  if (typeof url !== "string") throw new HttpsError("invalid-argument", "url must be a string.");

  await appControlRef.set(
    {
      update: {
        enabled,
        minVersion: minVersion.trim().slice(0, 20),
        message: message.trim().slice(0, 500),
        url: url.trim().slice(0, 500),
      },
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    } satisfies Partial<AppControlDoc>,
    { merge: true },
  );
  return { success: true };
});

export const setLimitedEvent = onCall(async (request) => {
  const uid = await requireAdmin(request.auth?.uid);
  const { active, title, description, endsAt } = request.data as {
    active?: unknown;
    title?: unknown;
    description?: unknown;
    endsAt?: unknown;
  };
  if (typeof active !== "boolean") throw new HttpsError("invalid-argument", "active must be a boolean.");
  if (typeof title !== "string") throw new HttpsError("invalid-argument", "title must be a string.");
  if (typeof description !== "string") {
    throw new HttpsError("invalid-argument", "description must be a string.");
  }
  if (endsAt !== null && endsAt !== undefined && typeof endsAt !== "string") {
    throw new HttpsError("invalid-argument", "endsAt must be an ISO date string or null.");
  }

  let endsAtTimestamp: Timestamp | null = null;
  if (typeof endsAt === "string") {
    const parsed = new Date(endsAt);
    if (Number.isNaN(parsed.getTime())) {
      throw new HttpsError("invalid-argument", "endsAt is not a valid date.");
    }
    endsAtTimestamp = Timestamp.fromDate(parsed);
  }

  await appControlRef.set(
    {
      event: {
        active,
        title: title.trim().slice(0, 80),
        description: description.trim().slice(0, 300),
        endsAt: endsAtTimestamp,
      },
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
    } satisfies Partial<AppControlDoc>,
    { merge: true },
  );
  return { success: true };
});

// Firestore caps a single batch at 500 writes; stay comfortably under it.
const NOTIFICATION_BATCH_SIZE = 400;

/**
 * Fans a one-off announcement out to every player's `notifications` inbox in
 * one shot — reuses the same inbox `NotificationsScreen` already renders
 * friend requests and duel challenges in, rather than inventing a second
 * "system messages" surface. `.select()` with no field paths pulls back only
 * document references (just the uids), not each user's full profile, since
 * that's all a fan-out needs.
 */
export const sendGlobalNotification = onCall(async (request) => {
  const uid = await requireAdmin(request.auth?.uid);
  const { title, message } = request.data as { title?: unknown; message?: unknown };
  if (typeof title !== "string" || title.trim().length === 0) {
    throw new HttpsError("invalid-argument", "title is required.");
  }
  if (typeof message !== "string" || message.trim().length === 0) {
    throw new HttpsError("invalid-argument", "message is required.");
  }
  const trimmedTitle = title.trim().slice(0, 80);
  const trimmedMessage = message.trim().slice(0, 500);

  const usersSnap = await db.collection("users").select().get();

  let batch = db.batch();
  let opsInBatch = 0;
  let sent = 0;

  for (const userDoc of usersSnap.docs) {
    batch.set(db.collection("notifications").doc(), {
      userId: userDoc.id,
      type: "announcement",
      fromUserId: uid,
      fromDisplayName: trimmedTitle,
      relatedId: "",
      read: false,
      createdAt: FieldValue.serverTimestamp(),
      title: trimmedTitle,
      message: trimmedMessage,
    } satisfies NotificationDoc);
    opsInBatch++;
    sent++;

    if (opsInBatch === NOTIFICATION_BATCH_SIZE) {
      await batch.commit();
      batch = db.batch();
      opsInBatch = 0;
    }
  }
  if (opsInBatch > 0) await batch.commit();

  // One call regardless of `sent` — every device subscribes itself to this
  // topic right after registering its FCM token (see
  // `PushNotificationService.subscribeToGlobalTopic`), so there's no need to
  // gather everyone's `fcmTokens` the way `sendPushToUser` does for a single
  // recipient.
  await sendPushToTopic(GLOBAL_ANNOUNCEMENTS_TOPIC, {
    title: trimmedTitle,
    body: trimmedMessage,
    data: { type: "announcement" },
  });

  return { success: true, sent };
});

const RESOLVABLE_NOTIFICATION_TYPES = ["friend_request", "duel_challenge"] as const;
type ResolvableNotificationType = (typeof RESOLVABLE_NOTIFICATION_TYPES)[number];

/** Which collection holds the "thing" each resolvable notification type is
 * about — `relatedId` is a doc id in this collection. */
const RELATED_COLLECTION_FOR_TYPE: Record<ResolvableNotificationType, string> = {
  friend_request: "friendships",
  duel_challenge: "duelInvites",
};

/**
 * One-off admin cleanup for notifications left behind by a bug where
 * `respondToFriendRequest`/`respondToDuelChallenge` updated the friendship/
 * invite doc on accept or decline but never touched the matching
 * notification — see those two functions' current form, which now deletes
 * it as part of responding. This callable is only for notifications that bug
 * already created before the fix landed.
 *
 * Deletes every `friend_request`/`duel_challenge` notification whose related
 * friendship/invite is no longer `"pending"` (already accepted, declined, or
 * expired) or has been deleted outright. Idempotent — safe to run more than
 * once, since a second run just finds nothing left to clean up.
 */
export const cleanupResolvedNotifications = onCall(async (request) => {
  await requireAdmin(request.auth?.uid);

  const notificationsSnap = await db
    .collection("notifications")
    .where("type", "in", RESOLVABLE_NOTIFICATION_TYPES)
    .get();

  if (notificationsSnap.empty) return { success: true, scanned: 0, deleted: 0 };

  // One read per notification's related doc to find out whether it's still
  // pending — a one-off admin cleanup, not a hot path, so `getAll` batching
  // those reads (rather than one at a time) is what matters here, chunked
  // the same conservative size the write batches below use.
  const notificationDocs = notificationsSnap.docs;
  const relatedRefs = notificationDocs.map((doc) => {
    const data = doc.data() as NotificationDoc;
    const collection = RELATED_COLLECTION_FOR_TYPE[data.type as ResolvableNotificationType];
    return db.collection(collection).doc(data.relatedId);
  });

  const relatedSnaps: FirebaseFirestore.DocumentSnapshot[] = [];
  for (let i = 0; i < relatedRefs.length; i += NOTIFICATION_BATCH_SIZE) {
    const chunk = relatedRefs.slice(i, i + NOTIFICATION_BATCH_SIZE);
    relatedSnaps.push(...(await db.getAll(...chunk)));
  }

  const staleDocs = notificationDocs.filter((_, index) => {
    const relatedSnap = relatedSnaps[index];
    if (!relatedSnap.exists) return true; // the friendship/invite is gone entirely
    return relatedSnap.data()?.status !== "pending";
  });

  let deleteBatch = db.batch();
  let opsInDeleteBatch = 0;
  for (const doc of staleDocs) {
    deleteBatch.delete(doc.ref);
    opsInDeleteBatch++;
    if (opsInDeleteBatch === NOTIFICATION_BATCH_SIZE) {
      await deleteBatch.commit();
      deleteBatch = db.batch();
      opsInDeleteBatch = 0;
    }
  }
  if (opsInDeleteBatch > 0) await deleteBatch.commit();

  return { success: true, scanned: notificationDocs.length, deleted: staleDocs.length };
});
