import { HttpsError, onCall } from "firebase-functions/v2/https";
import { db, FieldValue, Timestamp } from "../lib/admin";
import { AppControlDoc, NotificationDoc, UserDoc } from "../lib/types";

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

  return { success: true, sent };
});
