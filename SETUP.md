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
| flutter_riverpod | ^3.0.1 | Riverpod 3 is the current stable major; this project uses hand-written `Notifier`/`FamilyNotifier` classes rather than `riverpod_generator`, so there's no `build_runner` step to remember for state management. |
| go_router | ^17.0.0 | Current stable, official Flutter-team router. |
| firebase-admin (functions) | ^14.3.0 | Current Admin SDK for Node. |
| firebase-functions (functions) | ^7.3.2 | Current 2nd-gen Functions SDK. |
| firebase-tools (CLI) | ^15.29.0 | Current Firebase CLI. |
| Cloud Functions runtime | Node.js 22 | Current GA (non-beta) runtime as of scaffold time; matches `@types/node`. |
| @anthropic-ai/sdk | ^0.124.0 | Current TypeScript SDK for the Claude API. |
| Claude model | `claude-sonnet-5` | Set in `functions/src/lib/constants.ts` (`DEFAULT_CLAUDE_MODEL`), overridable via the `CLAUDE_MODEL` Cloud Functions environment param without a code change. |

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
2. **Upgrade to the Blaze (pay-as-you-go) plan.** Required for: Cloud
   Functions making outbound network calls (to the Claude API) and for
   scheduled functions (`expireStaleRounds`). At friend-group scale (dozens
   of users) this is normally a few cents to a few dollars a month.
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

Set your Claude API key as a **secret** (not a plain env var — this is the
key that must never leak):

```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
```

(Optional) override the model without touching code — create
`functions/.env` (already gitignored):

```bash
echo "CLAUDE_MODEL=claude-sonnet-5" > .env
```

Build once to check for TypeScript errors:

```bash
npm run build
```

## 7. Deploy Firestore rules, indexes, storage rules, and functions

```bash
firebase use --add          # first time only: pick your project, alias it "default"
firebase deploy --only firestore:rules,firestore:indexes,storage
firebase deploy --only functions
```

## 7.5. Seed some starter categories (optional, but you need this to actually play)

The app ships with zero categories out of the box — `categories` only gets
written to by players creating their own home-turf ones. To have something
playable immediately, `functions/src/seed/importOpenTriviaDb.ts` imports
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
Madrid → Barcelona), there are two ways to fill them with questions:

**No Claude API key needed** — `functions/src/seed/seedPregeneratedQuestions.ts`
uploads a starter pool of 5 hand-written questions per category (285
total, written directly rather than fetched from any API — see
`pregeneratedQuestions.ts`). Only needs Firebase Admin credentials:

```bash
cd functions && npm run build
GOOGLE_APPLICATION_CREDENTIALS=<path-to-a-service-account-key.json> \
  node lib/seed/seedPregeneratedQuestions.js
```

**Needs a Claude API key, gives you far more depth** —
`functions/src/seed/seedCategoryTaxonomy.ts` calls the Claude API (real,
if small, cost — see the comment at the top of that file for the expected
call count) to generate a much larger batch per category, the same logic
the in-app "Generate with AI" button uses. Run this after the pregenerated
one to top every category up, not instead of it:

```bash
cd functions && npm run build
GOOGLE_APPLICATION_CREDENTIALS=<path-to-a-service-account-key.json> \
  ANTHROPIC_API_KEY=sk-ant-... \
  node lib/seed/seedCategoryTaxonomy.js
```

Both scripts share the same category/group creation logic
(`taxonomyFirestore.ts`) and are safe to run in either order or repeatedly
— categories are never duplicated, only topped up with more questions.

To add more categories later (more clubs, more shows, whatever your group
actually wants to duel on), edit `functions/src/seed/categoryTaxonomy.ts`
and re-run — it skips categories that already exist and only adds
questions for new ones plus another batch for existing ones.

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

## Troubleshooting

- **"firebase_options.dart not found"** → you skipped `flutterfire
  configure` (step 3).
- **Google Sign-In fails silently on Android** → missing SHA-1 (step 4).
- **`generateQuestions` returns `permission-denied`** → you're calling it
  for a category you don't own; only the owner can generate for their own
  home-turf category.
- **`generateQuestions` returns `internal`** → check `firebase functions:log`
  — usually a missing/invalid `ANTHROPIC_API_KEY` secret, or Claude
  returned non-JSON (rare; the function already strips stray prose/fences).
