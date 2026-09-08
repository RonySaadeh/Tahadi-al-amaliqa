# Duel

The whole real-time 1v1 gameplay loop: challenging a friend, quick-matching,
playing rounds live, and seeing the result.

## Where things live

- `duel_controller.dart` — lobby actions: send/accept/decline a challenge,
  join/leave the open-lobby queue. Also exposes the stream providers used by
  the lobby screen (`incomingInvitesProvider`, `opponentCandidatesProvider`,
  `categoriesProvider`, `recentDuelsProvider`).
- `live_duel_controller.dart` — gameplay state, scoped per `duelId`:
  `duelStreamProvider`/`roundStreamProvider` mirror Firestore in real time,
  and `selectedAnswerProvider` tracks the local player's tap before the
  server confirms it.
- `screens/duel_lobby_screen.dart` — the "Duel" bottom-nav tab: incoming
  challenges, challenge-a-friend sheet, quick match button.
- `screens/live_duel_screen.dart` — the live round-by-round gameplay screen.
- `screens/duel_result_screen.dart` — win/lose/draw + ELO change + confetti.
- `widgets/` — duel-specific UI pieces (timer ring, VS scoreboard, answer
  tiles, score popup, invite card).

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

## Known simplification

`duel_lobby_screen.dart`'s quick-match button navigates immediately if
matched, but if you're placed in the open-lobby queue instead (no opponent
available yet), it doesn't currently listen for a match to land — you'd
need to back out and try again. A full implementation would watch the
`openLobbies/{lobbyId}` document and auto-navigate once a `duelId` appears
on it (the Cloud Function side already supports this — see
`functions/src/matchmaking/openLobby.ts`). Left as a fast-follow since a
small friend group can mostly rely on direct challenges.
