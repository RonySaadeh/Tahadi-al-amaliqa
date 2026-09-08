# Auth

Sign in / sign up with Email+Password, Google, or Apple, and make sure a
Firestore `users/{uid}` profile exists for the signed-in account.

## Where things live

- `auth_controller.dart` — the only place with auth business logic. Exposes
  `signInWithEmail`, `signUpWithEmail`, `signInWithGoogle`, `signInWithApple`,
  `signOut`, and creates the initial Firestore profile the first time a new
  user signs in (`_ensureProfileExists`).
- `screens/welcome_screen.dart` — the single screen signed-out users see;
  toggles between sign-in and sign-up. No logic here beyond form validation.
- `widgets/` — small, dumb form pieces (`AuthTextField`, `SocialSignInButton`)
  reused only within this feature.

## How "am I signed in" actually works

This feature does **not** hold a "signed in" boolean anywhere. The app's
router (`lib/routing/app_router.dart`) watches
`core/providers/core_providers.dart`'s `authStateChangesProvider`, which is a
live stream straight from `FirebaseAuth`. That single stream is the source
of truth for whether to show `WelcomeScreen` or the main app shell — so
there's no local state that can get out of sync with Firebase.

## Adding a new sign-in method

1. Add the SDK call to `core/services/firebase_auth_service.dart`.
2. Add a controller method here that calls it and then
   `_ensureProfileExists`.
3. Add a button in `welcome_screen.dart`.

## Apple Sign-In note

The code path exists and works, but Apple Sign-In requires an active Apple
Developer Program account (paid) with the "Sign in with Apple" capability
enabled, plus the entitlement added to the iOS project once you run
`flutter create` locally (see root `SETUP.md`). Until then, Email/Password
and Google cover you.
