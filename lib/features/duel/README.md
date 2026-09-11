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

Two players, two very different experiences of the same disconnect —
and `DuelPresenceController` is the *single* place that decides which of
the two any given device is having. Its `DuelPresenceState` can report a
self-drop or an opponent-drop but never both, and self always wins:

- **The player who lost their connection** gets `SelfDisconnectDialog` — a
  modal pop-up with the 35-second countdown
  (`AppConstants.duelReconnectGraceSeconds`) and a retry button. This side
  is cosmetic bookkeeping; see below for what actually ends the duel.
- **The still-connected opponent** gets `OpponentDisconnectDialog` — a
  modal pop-up naming the missing player and counting down to the automatic
  win. `DuelPresenceController` pings the `heartbeat` callable every
  `AppConstants.duelHeartbeatIntervalSeconds` and watches the *opponent's*
  last heartbeat (mirrored onto the duel doc as `player{1,2}LastSeenAt`);
  once it's stale past the grace period it calls `forfeitDuel`.

Three things that look like details but are the whole correctness story:

1. **A device decides it is connected by whether its own `heartbeat` calls
   land**, not by what `connectivity_plus` reports. A radio can be happily
   attached to a router that reaches nothing, and it is the server-side
   heartbeat that the opponent's forfeit gets judged against anyway.
2. **A device that can't see the world never accuses its opponent.** If our
   own heartbeats aren't landing, the opponent's heartbeat stops arriving
   for exactly that reason — so the self branch returns early and the
   opponent branch is never evaluated. Without this guard, a wobble on one
   side shows *both* players "your opponent disconnected".
3. **Staleness compares two readings of the same device's clock** — when we
   locally last *observed* the opponent's heartbeat advance, never our local
   clock against a server-stamped timestamp. Phone clocks run minutes off
   routinely, and comparing across the two made healthy duels look dead.
   This is also why `DuelModel.props` must include the `lastSeenAt` fields:
   a heartbeat is frequently the only field that changes between snapshots,
   and leaving them out of `Equatable` made `duelStreamProvider` dedupe the
   updates away, freezing presence for both players.

Consistent with "this feature never decides who's right" above: `heartbeat`
and `forfeitDuel` are both Cloud Functions (`functions/src/scoring/presence.ts`),
not direct Firestore writes, and `forfeitDuel` independently re-verifies the
opponent's staleness against the server-stamped heartbeat before honoring
it — a client claiming a forfeit doesn't make it one.
