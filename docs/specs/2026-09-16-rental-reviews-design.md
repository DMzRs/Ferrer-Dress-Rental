# Rental Reviews & Ratings — Design

Date: 2026-09-16 · Status: approved spec (approach A, all 4 sections signed off in chat)
Related: Ferrer Clothing Rental (`customer` / `admin` roles, admin-triggered returns)

## 1. Goal

Let customers leave feedback (1–5 stars + optional comment) on a rental once it
is finished/returned, and surface public item ratings on the catalog so future
shoppers see social proof. Editable by the review owner. No super-admin needed.

## 2. Background (verified in repo)

- Rental statuses: `pending, active, completed, cancelled, declined`
  (`lib/features/rentals/domain/entities/rental_entity.dart:45-63`); `overdue`
  is derived. There is no `returned` status.
- Return is admin-only: `ProcessReturnUseCase` flips `active/overdue → completed`
  + `returnedAt` (`lib/features/rentals/domain/usecases/process_return_usecase.dart:23-38`).
  Customers can only cancel (`rental_details_viewmodel.dart:18-34`).
- No review/rating/feedback code exists today (grep confirms only false positives).
- Rules today: rentals read admin-or-owner; owner updates limited to
  cancel-only touching `status, updatedAt` (`firestore.rules:74-95`).
- `AppConfig.firebaseEnabled` swaps Firebase ↔ in-memory mocks; new feature must
  work in both modes.

## 3. Data model (§1 approved)

New `reviews` collection, **doc ID = `rentalId`** (one review per rental by construction).

| Field | Type | Notes |
|---|---|---|
| `userId` | string | owner, forced `== auth.uid` on create |
| `userName` | string | denormalized for display |
| `itemId` | string | links public aggregate |
| `itemName` | string | denormalized for admin feed |
| `stars` | int 1–5 | required, validated client + rules |
| `comment` | string ≤ 500 | optional, trimmed |
| `createdAt` / `updatedAt` | timestamp | `updatedAt` stamped on every edit |

Clean-architecture split per existing convention:

- `lib/features/reviews/domain/entities/review_entity.dart` — `Review` + `isOwner`.
- `lib/features/reviews/data/models/review_model.dart` — `fromMap/toMap/fromEntity`.
- `lib/features/reviews/data/datasources/{review_data_source.dart,firebase_review_data_source.dart,mock_review_data_source.dart}`.
- `lib/features/reviews/data/repositories/review_repository_impl.dart` +
  `domain/repositories/review_repository.dart`.
- `lib/features/reviews/domain/usecases/{submit_review_usecase.dart,update_review_usecase.dart}`
  (submit = create-or-overwrite keyed by `rentalId`; guards: rental completed,
  caller is owner, stars 1–5).
- `FirestoreCollections.reviews = 'reviews'`.

Public item aggregate (no Cloud Function, keeps the no-backend pattern): two new
optional fields on `items/{id}` — `avgRating` (double, default 0) and
`ratingCount` (int, default 0) — bumped in a Firestore transaction from the
previous star value (delta: new reviews increment the count, overwrites adjust
the sum; `Transaction.get` in this SDK only takes single docs, so no
re-read-all). `CatalogItem`
/ `CatalogItemModel` gain the two fields with `0` defaults so old docs parse.

## 4. Rules, indexes, offline (§2 approved)

`firestore.rules` — new `match /reviews/{rentalId}` block:

- `create`: signed-in AND `request.resource.data.userId == request.auth.uid` AND
  `stars is int 1..5` AND `comment` (if present) `is string ≤ 500` AND the
  `rentals/{rentalId}` doc exists with `status == 'completed'` and
  `userId == request.auth.uid`.
- `update`: signed-in owner (`resource.data.userId == auth.uid`) AND
  `affectedKeys().hasOnly(['stars','comment','updatedAt'])`.
- `read`: any signed-in user (catalog + details need it).
- `delete`: `isAdmin()` only.
- Items aggregate write: item docs remain admin-writable today; the transaction
  runs with the signed-in customer, so `match /items/{id}` gains a narrow
  allowance: signed-in users may update **only** `avgRating, ratingCount`
  (mirrors the existing `status`-only customer allowance on items).

`firestore.indexes.json`: composite `reviews(itemId ASC, createdAt DESC)` for the
item-page recent list. Deploy: `firebase deploy --only firestore:rules,firestore:indexes`.

Mock mode: `MockReviewDataSource` (in-memory map keyed by `rentalId`, 2 seeded
samples) selected by `AppConfig.firebaseEnabled`, same as rentals.

## 5. Customer UI (§3 approved)

Two entry points on existing completed surfaces (no new routes):

1. `rental_card.dart` `else` branch (~line 202, completed/cancelled/declined):
   for `isCompleted` show a Rate pill — "Rate" (gold pulse once if unrated) or
   "★ 4.0" if rated — opening the sheet. Tap elsewhere still navigates to details.
2. `rental_details_screen.dart` Returned timeline section: "Your rating" row
   (stars or "Tap to rate"), same sheet.

Sheet: boutique bottom sheet (`showModalBottomSheet`, rounded 28, cream) with 5
tappable stars (rose→gold fill), optional comment `TextField` (multiline, 500
counter), Submit/Update button → `ReviewViewModel` (new, per-feature viewmodel
pattern; states idle/submitting/error). Submit on an existing review overwrites
it (edit-by-owner, `updatedAt` stamped) — no separate edit screen. No
auto-popups or push; the gold pulse animates once per session when an unrated
completed rental first renders — that pill is the only nudge.

## 6. Surfacing, errors, testing (§4 approved)

- Catalog: `item_details` header shows `★ {avg} ({count})`; "Recent reviews"
  section lists latest 5 (first-name, stars, comment, date) via the composite
  `reviews(itemId, createdAt)` index defined in §4;
  empty state: "No reviews yet — be the first".
- Admin: read-only reviews feed in `RentalManagementScreen` completed tab
  (stars + comment per rental). No moderation actions (YAGNI).
- Errors: stars-required client validation; rules rejections (not-completed,
  wrong owner, bad stars) mapped to friendly top-snackbar copy; aggregate
  transaction retries once — on failure show "Rating saved, count updating
  shortly" (review write already committed).
- Tests: `review_model_test` (round-trip, defaults), `review_usecases_test`
  (reject non-completed rental, reject stars 0/6, reject non-owner, overwrite
  keeps doc ID), widget test for the sheet (tap 4th star → submits stars=4);
  manual rules check in console; `flutter analyze` + full `flutter test` green.

## 7. Out of scope (explicit)

Push notifications, photo reviews, shop replies, moderation/reporting, helpful
votes, Cloud Functions, splitting private vs public feedback collections
(revisit only if comments prove sensitive).

## 8. File touch list

New: `lib/features/reviews/**` (entity, model, 3 datasources, repository impl +
interface, 2 use cases, viewmodel, bottom-sheet widget).
Edit: `firestore.rules`, `firestore.indexes.json`,
`lib/core/constants/firestore_collections.dart`,
`lib/features/inventory/.../catalog_item.dart` + model,
`lib/features/rentals/presentation/widgets/rental_card.dart`,
`lib/features/rentals/presentation/views/rental_details_screen.dart`,
item-details view, `RentalManagementScreen` completed tab, `main.dart` providers.
