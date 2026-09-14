# Home

The app's single main tab — raised and centered in the bottom nav (see
`AppShell`) as the thing this app is actually for. One scrolling page: the
arena rating header, incoming challenges, the quick-match/challenge-a-friend
actions with the category catalog to pick from, and a recent-duels list.

This used to be two tabs — Home (your stats) and Duel (starting a match).
They merged because they were never really two different errands: you come
to this tab either to check your rating or to start a duel, often both in
the same visit, and a separate tab for each just meant an extra hop. See
`features/duel/README.md` for the same note from the other side.

## Where things live

- `home_controller.dart` — just `currentUserProvider`, a stream of the
  signed-in player's own Firestore profile. That's the only state this
  feature owns.
- `screens/home_screen.dart` — the screen itself. Renders its own
  `currentUserProvider`/`recentDuelsProvider` data alongside providers it
  doesn't own — `incomingInvitesProvider`, `categoryGroupsProvider`,
  `categoriesProvider`, `selectedCategoryIdProvider`,
  `queuedLobbyIdProvider`, `duelControllerProvider` — all still defined and
  owned by `features/duel/duel_controller.dart`. If you're looking for
  where a quick-match or challenge action "does its thing," it's over in
  `features/duel/`; this screen only composes the UI around it.
- `widgets/arena_rating_header.dart` — the gold-on-violet rating hero.
- `widgets/recent_duel_tile.dart` — one row in the recent-duels list.
