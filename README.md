# تحدي العمالقة — Challenge of the Giants

A real-time, head-to-head trivia duel app for a friend group: challenge a
specific friend or quick-match into an open lobby, race to answer the same
question at the same time, climb a shared ELO ladder, and build a rivalry
record against each named friend. Players can also own up to 3 "home turf"
categories with their own questions, and earn a scoring bonus when someone
duels them there.

Arabic is the primary/default language (hence the name) with full English
support and RTL layout throughout.

## Stack

- **Client:** Flutter (Dart), Riverpod for state management, go_router for
  navigation.
- **Backend:** Firebase — Auth, Cloud Firestore (with real-time listeners
  for live duel state), Cloud Functions (TypeScript) for every piece of
  server-authoritative logic.

See `SETUP.md` for exact versions and why, and how to get this running.
If you're picking this up again after being away from a dev machine, use
`RUN_WHEN_HOME.md` instead — it's the fast checklist.

## Project layout

```
lib/
  core/            # constants, theme (design system), utils, low-level services
  data/
    models/        # plain Dart classes mirroring Firestore documents
    repositories/  # translate Firestore <-> models; the only thing features call
  features/        # one folder per feature — see the README.md inside each
  routing/         # go_router setup + the bottom-nav shell
  l10n/            # Arabic (default) + English translations

functions/
  src/
    scoring/       # resolveDuel.ts is the ONLY place points/ELO are computed
    questions/     # home-turf category/question CRUD
    matchmaking/   # challenge flow + quick-match open lobby
```

Every `lib/features/<name>/README.md` explains what that feature does and
exactly which file owns its logic — start there when getting back into a
part of the app after time away.

## The one architectural rule that matters most

**The client never decides who won, how many points a round was worth, or
what someone's new ELO is.** Every one of those is computed by a Cloud
Function (`functions/src/scoring/resolveDuel.ts`) and enforced by
`firestore.rules`, which blocks clients from writing `duels`, `rounds`,
`questions`, and `categories` directly. If a number in the app looks wrong,
that file — not a screen or controller — is almost always where the fix
belongs.
