# Setup

Full step-by-step setup. If you just want the fast "I'm at my computer,
let's go" checklist, use `RUN_WHEN_HOME.md` instead — this file is for the
first time you set the project up, or when something's misconfigured.

## Versions used, and why

Checked against pub.dev/npm on **2026-09-08** — the day this project was
scaffolded — rather than assumed. Pub/npm packages move fast, so if it's
been a while, run `flutter pub outdated` and `npm outdated` (in
`functions/`) before assuming these are still current.

| Tool / package | Version pinned here | Why |
|---|---|---|
| Flutter SDK | 3.47.x (stable channel) | Current stable at scaffold time. |
| Dart SDK | 3.13.x (bundled with Flutter 3.47) | Comes with the Flutter SDK above. |
| firebase_core | ^4.13.0 | Current FlutterFire release. |
| firebase_auth | ^6.5.7 | ” |
| cloud_firestore | ^6.8.0 | ” |
| cloud_functions | ^6.3.6 | ” |
| firebase_messaging | ^16.7.0 | Push notifications — see section 9 below. |
| flutter_riverpod | ^3.0.1 | Riverpod 3 is the current stable major; this project uses hand-written `Notifier`/`FamilyNotifier` classes rather than `riverpod_generator`, so there's no `build_runner` step to remember for state management. |
| go_router | ^17.0.0 | Current stable, official Flutter-team router. |
| firebase-admin (functions) | ^14.3.0 | Current Admin SDK for Node. |
| firebase-functions (functions) | ^7.3.2 | Current 2nd-gen Functions SDK. |
| firebase-tools (CLI) | ^15.29.0 | Current Firebase CLI. |
| Cloud Functions runtime | Node.js 22 | Current GA (non-beta) runtime as of scaffold time; matches `@types/node`. |

Models are hand-written (no `freezed`/`json_serializable`) — see the note
at the top of `pubspec.yaml` for why.

## 1. Install prerequisites

- **Flutter SDK** (3.47+): https://docs.flutter.dev/get-started/install —
  then `flutter doctor` and fix anything it flags.
- **Node.js 22**: https://nodejs.org (needed for Cloud Functions).
- **Firebase CLI**: `npm install -g firebase-tools`, then `firebase login`.
- **FlutterFire CLI**: `dart pub global activate flutterfire_cli`.

## 2. Create the Firebase project

1. https://console.firebase.google.com → **Add project**.
2. **Upgrade to the Blaze (pay-as-you-go) plan.** Required for: 2nd-gen
   Cloud Functions in general and for scheduled functions
   (`expireStaleRounds`). At friend-group scale (dozens of users) this is
   normally a few cents to a few dollars a month.
3. Enable **Authentication** → Sign-in method → turn on **Email/Password**
   and **Google**. Leave **Apple** off for now (see step 6).
4. Enable **Firestore Database** → production mode → pick a region close to
   your friend group.
5. Enable **Storage** (for profile photos).

## 3. Connect the Flutter app to Firebase

From the repo root:

```bash
flutterfire configure
```

Pick the project you just created, and select the platforms you want
(Android/iOS at minimum). This generates `lib/firebase_options.dart` plus
`android/app/google-services.json` and/or
`ios/Runner/GoogleService-Info.plist` — **none of these are committed to
git** (see `.gitignore`), so you run this once per machine you develop on.

If `android/`/`ios/` don't exist yet in your checkout, generate them first:

```bash
flutter create --org com.yourteam.tahadi --platforms=android,ios .
```

This only adds the platform folders — it won't touch your existing
`pubspec.yaml` or `lib/`. Then run `flutterfire configure`.

```bash
flutter pub get
```

## 4. Google Sign-In

- **Android:** get your debug SHA-1 (`cd android && ./gradlew signingReport`)
  and add it in Firebase console → Project settings → your Android app →
  Add fingerprint. Re-download `google-services.json` if it changed.
- **iOS:** `flutterfire configure` already adds the right URL scheme from
  `GoogleService-Info.plist`'s `REVERSED_CLIENT_ID` — no extra step needed
  for a simulator/dev build.

## 5. Apple Sign-In (optional, do this later)

Requires a paid Apple Developer Program membership. When you have one:

1. Apple Developer portal → your App ID → enable **Sign in with Apple**.
2. In Xcode (`ios/Runner.xcworkspace`) → Signing & Capabilities → **+
   Capability** → Sign in with Apple.
3. In Firebase console → Authentication → Sign-in method → enable **Apple**.

The Flutter code (`core/services/firebase_auth_service.dart`) already
supports it — this step is purely platform configuration.

## 6. Cloud Functions

```bash
cd functions
npm install
```

Build once to check for TypeScript errors:

```bash
npm run build
```

## 7. Deploy Firestore rules, indexes, storage rules, and functions

```bash
firebase use --add          # first time only: pick your project, alias it "default"
firebase deploy --only firestore:rules,firestore:indexes,storage
FUNCTIONS_DISCOVERY_TIMEOUT=120 firebase deploy --only functions
```

**Always check the deploy actually listed every function.** Before uploading,
the CLI boots your compiled code in a local server and asks it what functions
exist. On Windows that step routinely exceeds its silent 10-second default and
dies with `User code failed to load. Cannot determine backend specification.
Timeout after 10000` — at which point **nothing** deploys and whatever was
live before just stays live, so the app keeps running against a stale backend
that's missing your newest functions. `FUNCTIONS_DISCOVERY_TIMEOUT=120` (in
seconds) is what avoids it. Confirm with:

```bash
firebase functions:list     # should list all 10
```

## 7.5. Seed some starter categories (optional, but you need this to actually play)

The app ships with zero categories out of the box — `categories` is written
only by admin seed scripts, never by players. To have something playable
immediately, `functions/src/seed/importOpenTriviaDb.ts` imports
free English trivia questions from [Open Trivia DB](https://opentdb.com)
into 11 starter categories (General Knowledge, Film, Music, Television,
Video Games, Science & Nature, Sports, Geography, History, Animals, Anime
& Manga). It's a one-off script, not a deployed function — see the comment
at the bottom of that file for exact commands. Quick version, against your
real project:

```bash
cd functions && npm run build
gcloud auth application-default login   # once, if you haven't
GOOGLE_APPLICATION_CREDENTIALS=<path-to-a-service-account-key.json> \
  node lib/seed/importOpenTriviaDb.js
```

This only pulls free English questions — it doesn't touch the Arabic side.

For the full grouped, mostly-Arabic taxonomy — 10 groups (Sports, Movies &
TV, Arabic Cinema & Drama, Music, History, Geography, Science & Tech,
Video Games, Literature & General Knowledge, Food & Puzzles) with ~57
general + specific categories (e.g. Sports → Football General → Real
Madrid → Barcelona), `functions/src/seed/seedPregeneratedQuestions.ts`
uploads a hand-written starter pool per category, in both languages: 40-60
Arabic questions (see `pregeneratedQuestions.ts`) and 40-60 English
questions (see `pregeneratedQuestionsEn.ts`), written directly rather than
fetched from any API. A duel's language is fixed from whoever starts it (their
`locale` profile field — see the Profile screen's language toggle), and
`pickNextQuestion` picks each round's question from the matching language
pool. Only needs Firebase Admin credentials:

```bash
cd functions && npm run build
GOOGLE_APPLICATION_CREDENTIALS=<path-to-a-service-account-key.json> \
  node lib/seed/seedPregeneratedQuestions.js
```

Safe to run repeatedly, though re-running does add another copy of the
starter pool per category each time — see the comment at the top of that
file. To add more categories later (more clubs, more shows, whatever your
group actually wants to duel on), edit
`functions/src/seed/categoryTaxonomy.ts` and add matching entries to
`pregeneratedQuestions.ts`/`pregeneratedQuestionsEn.ts`, then re-run.

## 8. Run it

Local emulators (Auth + Firestore + Functions + Storage, no real Firebase
usage/cost):

```bash
firebase emulators:start
```

In another terminal, run the Flutter app pointed at those emulators:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

(Android emulator reaching your host machine works automatically; if you hit
connection issues there, see `main.dart` — `EMULATOR_HOST` is overridable.)

Or, once functions are deployed and rules are live, just run against the
real project:

```bash
flutter run
```

## 9. Push Notifications (FCM)

All the code is already in place — client token registration
(`PushNotificationService`/`push_notifications_controller.dart`) and
server-side sending (`functions/src/lib/push.ts`, wired into
`sendFriendRequest`, `respondToFriendRequest`, `sendDuelChallenge`,
`respondToDuelChallenge`, and `sendGlobalNotification`). What's left is
platform configuration, same category of step as Apple Sign-In (step 5) —
Firebase's client SDKs need each platform's own push transport wired up,
and that can't be committed to git (see `.gitignore`'s note on
`android`/`ios`).

**Android:** nothing extra beyond step 3 (`flutterfire configure`, which
writes `google-services.json`) — the `firebase_messaging` plugin's own
manifest merge handles the rest, including requesting the Android 13+
notification permission at runtime (`PushNotificationService.
requestPermissionAndGetToken`, called automatically once signed in). If you
want a custom small-icon instead of the launcher icon in the notification
shade, drop a white-on-transparent PNG at
`android/app/src/main/res/drawable/ic_notification.png` and add
`<meta-data android:name="com.google.firebase.messaging.default_notification_icon" android:resource="@drawable/ic_notification" />`
inside `<application>` in `AndroidManifest.xml` — optional, skip it and the
launcher icon is used.

**iOS:** requires a paid Apple Developer Program membership (same
prerequisite as step 5) and two things Xcode/the portal have to do, which
no committed file can stand in for:

1. In Xcode (`ios/Runner.xcworkspace`) → Signing & Capabilities → **+
   Capability** → add both **Push Notifications** and **Background Modes**
   (check "Remote notifications" under it).
2. Apple Developer portal → Certificates, Identifiers & Profiles → Keys →
   create a new key with **Apple Push Notifications service (APNs)**
   enabled, download the `.p8` file. Then Firebase console → Project
   settings → Cloud Messaging → your iOS app → **Apple app configuration**
   → upload that key (needs your Team ID and Key ID, both shown next to it
   in the portal).

Until that key is uploaded, iOS pushes silently fail to send (no error
surfaces to the player) — Android and the in-app inbox both work
regardless, so this is safe to leave for later.

**Testing it:** sign in on two devices/simulators as two different
accounts, friend each other or send a duel challenge, and background the
receiving device — the push should arrive within a few seconds. For a
broadcast, use the "Send Global Notification" section of the App Control
panel (see `features/app_control/README.md` for how to become an admin).

## Troubleshooting

- **"firebase_options.dart not found"** → you skipped `flutterfire
  configure` (step 3).
- **Google Sign-In fails silently on Android** → missing SHA-1 (step 4).
- **Push notifications never arrive on iOS, Android works fine** → the APNs
  key hasn't been uploaded to Firebase console yet (step 9).
