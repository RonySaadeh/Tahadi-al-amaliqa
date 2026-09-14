# Profile

Your own stats dashboard: avatar, editable display name, win/loss/streak/
ELO tiles.

## Where things live

- `profile_controller.dart` — the only feature-specific action is
  `updateDisplayName`. Everything this screen displays is read from
  providers owned by other features on purpose (see below) rather than
  duplicated here.
- `screens/profile_screen.dart` — the screen itself.
- `widgets/stat_tile.dart` — one stat card in the stats grid.

## Why this controller is so small

- The profile data itself is `currentUserProvider`, defined in
  `features/home/home_controller.dart` — there's one stream of "my
  profile" for the whole app, and every feature that needs it reads from
  that rather than duplicating it.

If wins/losses/ELO/streak look wrong here, that's not a bug in this
feature — those fields are only ever written by `resolveDuel` (see
`functions/src/scoring/resolveDuel.ts`), so start there.
