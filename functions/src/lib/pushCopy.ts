/**
 * Push notification title/body text, mirroring the in-app inbox templates
 * in `lib/l10n/app_en.arb`/`app_ar.arb` (`friendsRequestBody`,
 * `notificationsChallengeBody`, etc.) so a push and the inbox entry it
 * accompanies never disagree in wording. Kept here rather than pulled from
 * the Flutter ARB files directly since Cloud Functions is a separate
 * deployable with no access to them — if you change one side, change the
 * other to match.
 *
 * Only `"en"`/`"ar"` exist (this app's only two locales, per `UserDoc.locale`);
 * anything else falls back to English.
 */

interface PushCopy {
  friendRequestTitle: string;
  friendRequestBody: (name: string) => string;
  friendRequestAcceptedTitle: string;
  friendRequestAcceptedBody: (name: string) => string;
  duelChallengeTitle: string;
  duelChallengeBody: (name: string) => string;
  duelChallengeAcceptedTitle: string;
  duelChallengeAcceptedBody: (name: string) => string;
}

const EN: PushCopy = {
  friendRequestTitle: "New Friend Request",
  friendRequestBody: (name) => `${name} wants to add you as a friend.`,
  friendRequestAcceptedTitle: "Friend Request Accepted",
  friendRequestAcceptedBody: (name) => `${name} accepted your friend request.`,
  duelChallengeTitle: "Duel Challenge",
  duelChallengeBody: (name) => `${name} challenged you to a Trivia Game.`,
  duelChallengeAcceptedTitle: "Challenge Accepted",
  duelChallengeAcceptedBody: (name) => `${name} accepted your challenge! Tap to join.`,
};

const AR: PushCopy = {
  friendRequestTitle: "طلب صداقة جديد",
  friendRequestBody: (name) => `${name} يريد إضافتك كصديق.`,
  friendRequestAcceptedTitle: "تم قبول طلب الصداقة",
  friendRequestAcceptedBody: (name) => `${name} قبل طلب صداقتك.`,
  duelChallengeTitle: "تحدي مبارزة",
  duelChallengeBody: (name) => `${name} تحداك في لعبة تحدي معلومات.`,
  duelChallengeAcceptedTitle: "تم قبول التحدي",
  duelChallengeAcceptedBody: (name) => `${name} قبل تحديك! اضغط للانضمام.`,
};

export function pushCopyFor(locale: string | undefined): PushCopy {
  return locale === "ar" ? AR : EN;
}
