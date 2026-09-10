# Run when home

Fast checklist to get from "just sat down at my computer" to a running app.
Full explanations are in `SETUP.md` — this is just the commands.

## First time only on this machine

```bash
git clone <your-repo-url> && cd Tahadi-al-amaliqa
npm install -g firebase-tools           # if you don't have it
dart pub global activate flutterfire_cli
firebase login
```

## Every time (including first time)

```bash
git pull
flutter pub get
```

**Missing `android/`/`ios/` folders?** (fresh clone, first machine setup):

```bash
flutter create --org com.yourteam.tahadi --platforms=android,ios .
```

**Missing `lib/firebase_options.dart`?** (first machine setup, or it got
wiped):

```bash
flutterfire configure
```

**Missing `functions/node_modules/`?**

```bash
cd functions && npm install && cd ..
```

## Run it

Local emulators (no real Firebase usage, resets on restart):

```bash
firebase emulators:start
# new terminal:
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

Real Firebase project:

```bash
flutter run
```

## If something's red

- Analyzer errors about `firebase_options.dart` or `app_localizations.dart`
  → run `flutter pub get` (generates localizations) and `flutterfire
  configure` (generates firebase_options.dart) — see above.
- Cloud Function changes not showing up → `cd functions && npm run build`
  then redeploy (`firebase deploy --only functions`) or restart the
  emulator.
- Anything else → `SETUP.md` → Troubleshooting.
