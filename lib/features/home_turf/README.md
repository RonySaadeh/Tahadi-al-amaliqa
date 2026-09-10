# Home Turf

Each player can own up to 3 categories, hand-write questions for them, and
earns a scoring multiplier when someone duels them on their own category.

## Where things live

- `home_turf_controller.dart` — create a category or add a question. Also
  `myCategoriesProvider` / `categoryQuestionsProvider`. Every write
  forwards to a Cloud Function (`data/repositories/question_repository.dart`)
  — this feature never writes `categories`/`questions` documents directly.
- `screens/home_turf_screen.dart` — "my categories" list + create dialog.
- `screens/category_detail_screen.dart` — one category's question bank:
  manual add-question sheet.
- `widgets/` — `CategoryCard` (also reused by
  `features/duel/screens/category_picker_screen.dart` for visual
  consistency between "my categories" and the global picker), `QuestionTile`.

Home-turf categories always have `groupId: null` — grouping is only used
for the seeded global taxonomy (see `features/duel/README.md` § Category
groups); a player's own categories aren't sorted into Sports/Movies/etc.

## Why categories/questions are never written directly from here

If a client could write straight to `questions`, anyone could plant a
rigged question with a wrong "correct" answer to win duels. So both
collections are client-read-only (see `firestore.rules`), and this feature
only ever calls the `createHomeTurfCategory` and `addHomeTurfQuestion`
Cloud Functions, which validate everything (including the
3-category-per-owner cap) before writing.

## Where the home-turf scoring bonus actually applies

Nothing in this feature computes the bonus. When a duel is created on a
home-turf category, `matchmaking/createDuel.ts` stamps
`isHomeTurfDuel`/`homeTurfOwnerId` onto the duel document, and
`scoring/resolveDuel.ts` reads those fields to multiply the owner's points.
This feature's only job is letting the owner curate the category.
