import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

// Initialized once and imported everywhere else — every function file
// imports `db` from here instead of calling `initializeApp()` itself.
if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();
export const messaging = getMessaging();
export { FieldValue, Timestamp };
