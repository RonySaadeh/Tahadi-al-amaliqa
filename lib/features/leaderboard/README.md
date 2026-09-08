# Leaderboard

Global ELO ranking, plus a per-pair head-to-head record when you tap
another player.

## Where things live

- `leaderboard_controller.dart` — `globalLeaderboardProvider` (all users
  ordered by ELO) and `headToHeadProvider` (record between two specific
  uids).
- `screens/leaderboard_screen.dart` — the ranked list + the head-to-head
  bottom sheet.
- `widgets/leaderboard_row.dart` — one ranked row (medal color for top 3,
  highlighted if it's you).

## Why there's no "compute standings" logic here

Both providers are direct reads — no aggregation happens on the client.
`users` is already ordered by `elo` (a single Firestore query), and
`leaderboardPairings/{pairingId}` is a precomputed head-to-head document
that the `resolveDuel` Cloud Function updates every time a duel between
that pair finishes. If a number here looks wrong, the fix is almost always
in `functions/src/scoring/resolveDuel.ts`, not in this feature.
