# Home

The landing tab: greeting, ELO stat card, the two entry points into a duel
(challenge a friend / quick match), and a recent-duels list.

## Where things live

- `home_controller.dart` — just `currentUserProvider`, a stream of the
  signed-in player's own Firestore profile. That's the only state this
  feature owns.
- `screens/home_screen.dart` — the screen itself.
- `widgets/` — `EloStatCard` (the gold hero stat tile) and
  `RecentDuelTile` (one row in the recent-duels list).

## Why this feature is so thin

The "challenge a friend" and "quick match" buttons here just navigate to
the Duel tab (`AppRoutes.duelLobby`) rather than duplicating that flow —
all of the actual challenge/matchmaking logic lives in
`features/duel/duel_controller.dart`, including the `recentDuelsProvider`
this screen displays. If you're looking for where a home-screen action
"does its thing," it's almost always over in `features/duel/`.
