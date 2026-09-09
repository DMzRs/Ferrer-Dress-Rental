# Ferrer Clothing Rental

Premium dress & kiddie costume rental app built with Flutter + Firebase.

- **Customers** browse the catalog, rent dresses/costumes, book fitting appointments, and track their rentals.
- **Admins** manage inventory, process returns, review appointments, and view revenue reports.

## Project structure

```
lib/
├── core/                  # config, services (Firebase), theme, router, shared widgets
├── features/
│   ├── auth/              # sign in / sign up / password reset (Firebase Auth, email+password)
│   ├── home/              # catalog browsing & search
│   ├── item_details/      # item detail + book appointment
│   ├── booking/           # appointment scheduling (calendar + time slots)
│   ├── checkout/          # rental checkout (creates a rental + marks item rented)
│   ├── rentals/           # my rentals, rental details, cancel
│   ├── shell/             # user bottom-nav shell + profile
│   └── admin/             # dashboard, inventory mgmt, rental mgmt, reports
```

Every feature follows a clean-architecture split: `data/datasources` (Firebase + Mock), `data/repositories`, `domain` (entities, repositories, use cases), `presentation` (viewmodels + views). Data sources are swapped by `AppConfig.firebaseEnabled` — Firebase when `Firebase.initializeApp()` succeeds, mocks otherwise (useful for running with no network).

## Firebase setup

Project: **`ferrer-rental-shop`** (Android + iOS configured via `lib/firebase_options.dart` and `android/app/google-services.json`).

Firestore uses a **named database**: `ferrer-db` (asia-southeast1), referenced in `lib/core/services/app_firestore.dart`.

### One-time console steps (required before first run)

1. **Enable Email/Password sign-in** — Firebase Auth has never been initialized on this project.
   Open [Authentication in the Firebase console](https://console.firebase.google.com/project/ferrer-rental-shop/authentication), click **Get started**, then enable **Email/Password** and save. Without this, sign-in/sign-up fails with `CONFIGURATION_NOT_FOUND`.
2. **Create the admin account** — sign up through the app (creates a `customer`), then in the console: Firestore → database `ferrer-db` → `users` collection → open the user's document → change `role` to `admin`. That user gets the Admin Shell on next launch. Security rules prevent users from ever setting `role` themselves.

### Firestore configuration (already deployed)

- `firestore.rules` — security rules; deployed to the `ferrer-db` database via `firebase.json`.
  - `users`: read own; admin reads all; sign-up creates own profile with role forced to `customer`; nobody can edit their own `role`.
  - `items`: signed-in read; only admins create/delete/edit — except the `status` field, which signed-in users may flip as part of checkout/cancel flows.
  - `rentals` / `appointments`: users read/create/update only their own docs (create forces `userId == auth.uid`); users may only cancel (`status: 'cancelled'`); admins do everything else.
- `firestore.indexes.json` — composite indexes for the two user-scoped queries:
  - `rentals(userId ASC, createdAt DESC)`
  - `appointments(userId ASC, scheduledAt DESC)`

Deploy changes after editing:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

`.firebaserc` pins the CLI to the `ferrer-rental-shop` project.

## Running

```bash
flutter pub get
flutter run                # uses Firebase when initialize() succeeds
```

If Firebase initialization fails (no network / bad config), the app transparently falls back to in-memory mock data, so the UI still runs end-to-end.

## Notes & known limitations

- Item `status` transitions (`available` ↔ `rented`) are performed client-side by the use cases. The rules limit non-admin writes to the `status` field only, but a determined user could still flip availability directly; moving this to a Cloud Function would close that gap.
- The admin dashboard counts users by streaming the whole `users` collection (admin-only under the rules). For large user bases, switch to an aggregate `count()` query.
