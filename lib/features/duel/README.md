# Duel

The whole real-time 1v1 gameplay loop: challenging a friend, quick-matching,
playing rounds live, and seeing the result.

## Where things live

- `duel_controller.dart` — lobby actions: send/accept/decline a challenge,
  join/cancel the open-lobby quick-match queue. Also exposes the stream
  providers used by the lobby screen (`incomingInvitesProvider`,
  `opponentCandidatesProvider`, `categoriesProvider`, `recentDuelsProvider`,
  `openLobbyStreamProvider`) and `queuedLobbyIdProvider`, which tracks
  whether we're currently waiting in the quick-match queue.
- `live_duel_controller.dart` — gameplay state, scoped per `duelId`:
  `duelStreamProvider`/`roundStreamProvider` mirror Firestore in real time,
  `selectedAnswerProvider` tracks the local player's tap before the server
  confirms it, and `duelPresenceProvider`/`DuelPresenceController` handle
  connection-loss detection (see below).
- `screens/duel_lobby_screen.dart` — the "Duel" bottom-nav tab: incoming
  challenges, the category catalog, challenge-a-friend sheet, quick match
  button.
- `widgets/category_catalog.dart` — the browsable category catalog shown
  inline on the lobby screen (see "Category groups" below).
- `screens/live_duel_screen.dart` — the live round-by-round gameplay screen.
- `screens/duel_result_screen.dart` — win/lose/draw + ELO change + confetti.
- `widgets/` — duel-specific UI pieces (timer ring, VS scoreboard, answer
  tiles, score popup, invite card).

## Category groups

With the seeded taxonomy (`functions/src/seed/categoryTaxonomy.ts`) there
are ~60 categories, so a flat dropdown stops being usable. Categories
belong to a `categoryGroups/{groupId}` section (Sports, Movies & TV, ...) —
`categoryGroupsProvider`/`categoriesProvider` in `duel_controller.dart`
feed `CategoryCatalog`, which groups them client-side by `groupId`, sorts
groups by their `order` field, and renders each group as a horizontally
scrollable row of chips rather than one long vertical list — a catalog to
skim rather than a picklist to search. Home-turf categories have no group
(`groupId: null`) and show up in a trailing "Home Turf" section instead.
There's no in-app way to create a group — only the seed script does that.

The selected category lives in `selectedCategoryIdProvider`
(`duel_controller.dart`) rather than local widget state, for the same
`ShellRoute`-disposal reason as `queuedLobbyIdProvider` below — tapping the
already-selected chip again clears it back to "any category".

## The most important rule in this feature

**This feature never decides who's right or how many points anything is
worth.** Every score, correctness flag, and ELO change comes from a Cloud
Function and arrives here purely as data on `duels/{duelId}` and
`duels/{duelId}/rounds/{n}` documents. See
`functions/src/scoring/resolveDuel.ts` — if you're debugging "why did I get
the wrong number of points," that file (not anything here) is where the
math lives.

The client's only write is `submitAnswer` (a callable Cloud Function, not a
direct Firestore write) — see `core/services/cloud_functions_service.dart`.

## How a round "advances" without any explicit code for it

There's no `nextRound()` method anywhere in the client. `LiveDuelScreen`
watches `duel.currentRound` from `duelStreamProvider`; when the
round-resolution Cloud Function increments `currentRound` on the duel
document, the widget rebuilds and starts watching the next round's document
instead. Advancing state lives entirely on the server; the client is just
reacting to whatever `currentRound` currently is.

## How quick-match auto-navigation works

`duel_lobby_screen.dart`'s quick-match button navigates immediately if
`joinQuickMatch` finds a waiting opponent right away. Otherwise the
returned `lobbyId` is stored in `queuedLobbyIdProvider` and the screen
switches to a "searching" state. From then on `openLobbyStreamProvider`
keeps listening to `openLobbies/{lobbyId}` in real time; when some *other*
player's `joinOpenLobby` call matches into that entry, the Cloud Function
stamps a `duelId` onto it (see `functions/src/matchmaking/openLobby.ts`),
and `ref.listen` in the lobby screen picks that up and navigates straight
into the live duel — no polling, no manual refresh.

`queuedLobbyIdProvider` lives in `duel_controller.dart` rather than as
local widget state specifically so it survives switching to another
bottom-nav tab and back while still queued (go_router's `ShellRoute`
disposes/recreates `DuelLobbyScreen` on tab switches, but Riverpod
providers are not tied to the widget tree).

## Losing connection mid-duel

Two players, two very different experiences of the same disconnect:

- **The player who lost their connection** sees this from
  `LiveDuelScreen`'s own `connectivityStatusProvider` watch — no server
  round-trip needed, since it's their own device that knows it's offline.
  `SelfReconnectOverlay` blocks the screen with a local 35-second countdown
  (`AppConstants.duelReconnectGraceSeconds`) and a manual retry button. It's
  purely cosmetic bookkeeping on this side — see below for what actually
  ends the duel.
- **The still-connected opponent** has no direct way to observe the other
  player's radio state, so `DuelPresenceController` pings the `heartbeat`
  callable every `AppConstants.duelHeartbeatIntervalSeconds` while the duel
  is active, and watches the *opponent's* last heartbeat (mirrored onto the
  duel doc as `player{1,2}LastSeenAt`). Once it's stale past the same
  35-second grace period, `OpponentReconnectBanner` shows a countdown and
  `DuelPresenceController` calls `forfeitDuel` — awarding itself the win.

Consistent with "this feature never decides who's right" above: `heartbeat`
and `forfeitDuel` are both Cloud Functions (`functions/src/scoring/presence.ts`),
not direct Firestore writes, and `forfeitDuel` independently re-verifies the
opponent's staleness against the server-stamped heartbeat before honoring
it — a client claiming a forfeit doesn't make it one.
