# App Control

A live remote-control panel for the whole app: an admin flips switches from
inside the app itself and every signed-in (and signed-out) client reacts
instantly, no redeploy needed. Four things it can do:

- **Maintenance Mode** — blocks every player behind a full-screen message
  while you're doing something disruptive server-side.
- **Force Update** — blocks players on a build older than a minimum version
  behind a screen with a link to update.
- **Limited-Time Event** — shows a dismissible banner across every tab while
  it's live, with an optional end time after which it disappears on its own.
- **Send Global Notification** — a one-off announcement delivered instantly
  into every player's existing notification inbox.

## Where things live

- `app_control_controller.dart` — `isAppAdminProvider` (derived from the
  signed-in player's own `UserModel.isAdmin`) and `AppControlController`, a
  thin pass-through to `AppControlRepository`'s four admin callables.
- `screens/app_control_screen.dart` — the admin panel itself, reachable from
  the Profile tab's settings drawer (only shown there when `isAdmin` is
  true). Four independent sections, each with its own Save/Send.
- `screens/maintenance_screen.dart` / `screens/force_update_screen.dart` —
  the full-screen blocks shown to *everyone* (not just admins) when the
  matching flag is on. Neither lives inside the bottom-nav shell — see
  `AppRoutes.maintenance`/`AppRoutes.updateRequired` and the redirect logic
  in `routing/app_router.dart`, which is what actually decides when to show
  them, on every navigation.
- `widgets/event_banner.dart` — the limited-time event strip, mounted once
  in `AppShell` above every tab.

## The data model

Everything lives in one document, `appControl/status` (see
`AppControlModel` and `FirestorePaths.appControl`) — a live stream watched
by `appControlProvider` in `core/providers/core_providers.dart`. That
provider is read from three places: the router's redirect (to gate
navigation), `AppShell` (for the event banner), and this feature's own
screens.

## Why every write goes through a Cloud Function

Same rule this whole app already follows for anything trust-sensitive (see
`CloudFunctionsService`'s doc comment): `firestore.rules` blocks **every**
client write to `appControl/status`, admin or not. Each of the four
callables in `functions/src/admin/appControl.ts` re-checks
`users/{uid}.isAdmin` itself before writing — the panel's UI hiding itself
from non-admins is a convenience, not the actual boundary.

## Becoming an admin

`isAdmin` isn't in `UserModel.editableFields`, and there's no callable that
grants it — a player can never make themselves an admin. Whoever should have
access gets `isAdmin: true` set by hand on their `users/{uid}` document in
the Firebase console. There's exactly one of these panels; it's meant for
the person running the app, not a role players can be promoted into
in-app.

## Send Global Notification isn't a toggle

Unlike the other three sections, it doesn't read back a saved state — it's a
fire-and-forget action. `sendGlobalNotification` (the callable) writes one
`notifications/{id}` document per player (`NotificationType.announcement`,
carrying its own `title`/`message` instead of being derived from a related
doc the way friend requests and duel challenges are) and there's nothing to
undo afterward; see `NotificationTile`'s early-return branch for how an
announcement renders differently from those two.
