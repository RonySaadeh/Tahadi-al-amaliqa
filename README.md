# تحدي العمالقة — Challenge of the Giants

A real-time, head-to-head trivia duel app for a friend group: challenge a
specific friend or quick-match into an open lobby, race to answer the same
question at the same time, climb a shared ELO ladder, and build a rivalry
record against each named friend. Players can also own up to 3 "home turf"
categories with their own questions, and earn a scoring bonus when someone
duels them there.

English is the primary/default language; Arabic is fully supported with RTL
layout throughout and is reachable from the profile's language toggle.

## Design system — "the arena"

The visual identity is built on one idea: the light surfaces are where you
*browse*, and dark "arena" fields punched out of them are where you
*compete*. The pieces that carry it:

- `core/theme/app_colors.dart` — the light palette plus the arena tokens
  (`arenaDark`, `arenaDeep`, `arenaRaised`, `clashYellow`) and the outcome
  gradients.
- `core/theme/app_typography.dart` — a two-voice type system: **Titan One**
  for display (logo, scores, ratings, verdicts) and **Outfit** for
  everything else, collapsing onto **Tajawal** in Arabic since neither Latin
  face has Arabic coverage. This is why the theme is built per-locale.
- `core/widgets/slab_button.dart` — the physical press: a slab on a hard
  zero-blur edge that travels into the page when tapped.
- `core/widgets/arena_panel.dart` — `ArenaPanel` (full-bleed dark region
  with a diagonal lower edge) and `ClashBackdrop` (the tilted two-color
  seam behind the live duel).
- `core/widgets/giants_logo.dart` — the monogram and wordmark lockups.
- `core/utils/rank_tier.dart` — turns a raw ELO number into a name a player
  can want (Novice Clay → Colossus Mythic).

Two rules worth keeping if you extend this: **avoid `Card`** — separate
surfaces with tint, space or a hairline instead — and let hero elements
overlap the boundaries they sit on rather than stacking in a column. Fonts
are bundled under `assets/fonts/` rather than fetched at runtime, so the
identity can't silently degrade to Roboto on a bad connection.

`test/design_system_test.dart` renders every one of these at a 390x844
viewport; run it after layout changes, since overflow is the failure mode
this style invites and the analyzer can't see it.

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
  l10n/            # English (default) + Arabic translations

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
