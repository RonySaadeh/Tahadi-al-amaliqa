import { logger } from "firebase-functions/logger";
import { db, FieldValue, messaging } from "./admin";
import { UserDoc } from "./types";

/** FCM topic every signed-in device subscribes to right after registering
 * its token — see `PushNotificationService.subscribeToGlobalTopic` on the
 * client. Lets `sendGlobalNotification` broadcast in one call regardless of
 * how many players exist, instead of reading every user's `fcmTokens`. */
export const GLOBAL_ANNOUNCEMENTS_TOPIC = "global_announcements";

/** FCM error codes for a token that will never work again (app uninstalled,
 * token rotated out from under us, malformed). Safe to drop from the user's
 * `fcmTokens` the instant we see one, rather than leaving it to a separate
 * cleanup pass — the send-time equivalent of `cleanupResolvedNotifications`. */
const DEAD_TOKEN_ERROR_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

interface PushPayload {
  title: string;
  body: string;
  /** Read by `PushNotificationService`'s tap handler to navigate — every
   * value must be a string, FCM's own requirement for the data payload. */
  data?: Record<string, string>;
}

/**
 * Sends a push to every device `uid` is currently signed in on. A no-op if
 * they have none registered (push notifications were never a requirement to
 * use this app — the in-app inbox `NotificationDoc` this always accompanies
 * is the fallback).
 *
 * Never throws: by the time anything calls this, the friend request/duel
 * challenge/etc. it's a side effect of has already succeeded, so an FCM
 * outage or a dead token is logged and swallowed rather than failing the
 * whole callable over what is, worst case, a missed push.
 */
export async function sendPushToUser(uid: string, payload: PushPayload): Promise<void> {
  try {
    const userSnap = await db.collection("users").doc(uid).get();
    const tokens = (userSnap.data() as UserDoc | undefined)?.fcmTokens ?? [];
    if (tokens.length === 0) return;

    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: payload.title, body: payload.body },
      data: payload.data,
    });

    const deadTokens: string[] = [];
    response.responses.forEach((result, index) => {
      const errorCode = result.error?.code;
      if (!result.success && errorCode && DEAD_TOKEN_ERROR_CODES.has(errorCode)) {
        deadTokens.push(tokens[index]);
      }
    });

    if (deadTokens.length > 0) {
      await db
        .collection("users")
        .doc(uid)
        .update({ fcmTokens: FieldValue.arrayRemove(...deadTokens) });
    }
  } catch (error) {
    logger.error(`sendPushToUser(${uid}) failed`, error);
  }
}

/** Broadcasts to every device subscribed to `topic` in one call — see
 * `GLOBAL_ANNOUNCEMENTS_TOPIC` and `sendGlobalNotification`. Never throws,
 * for the same reason `sendPushToUser` doesn't. */
export async function sendPushToTopic(topic: string, payload: PushPayload): Promise<void> {
  try {
    await messaging.send({
      topic,
      notification: { title: payload.title, body: payload.body },
      data: payload.data,
    });
  } catch (error) {
    logger.error(`sendPushToTopic(${topic}) failed`, error);
  }
}
