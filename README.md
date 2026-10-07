# Ferrer Clothing Rental

Premium dress & kiddie costume rental app built with Flutter + Firebase.

- **Customers** browse the catalog, rent dresses/costumes, book fitting appointments, track rentals, and chat with the shop.
- **Admins** manage inventory, process rentals and returns, review appointments, moderate reviews, answer chats, and view revenue reports.
- **Superadmins** register admin accounts, manage roles, view business metrics, and review the audit trail.

## Project structure

```
lib/
├── core/                  # config, services (Firebase), theme, router, shared widgets
├── features/
│   ├── auth/              # email/password, email-link, Google sign-in; roles
│   ├── home/              # catalog browsing & search
│   ├── item_details/      # item detail + book appointment
│   ├── booking/           # appointment scheduling (calendar + time slots)
│   ├── checkout/          # rental checkout (creates a rental + marks item rented)
│   ├── rentals/           # my rentals, rental details, cancel
│   ├── shell/             # user bottom-nav shell + profile
│   ├── messaging/         # customer↔shop chat threads, read markers, badges
│   ├── notifications/     # rental/appointment activity feed
│   ├── reviews/           # ratings on completed rentals
│   ├── audit/             # append-only audit trail (entries, logger, repo)
│   ├── superadmin/        # superadmin shell: accounts, metrics, logs
│   └── admin/             # dashboard, inventory mgmt, rental mgmt, reports
```

Every feature follows a clean-architecture split: `data/datasources` (Firebase + Mock), `data/repositories`, `domain` (entities, repositories, use cases), `presentation` (viewmodels + views). Data sources are swapped by `AppConfig.firebaseEnabled` — Firebase when `Firebase.initializeApp()` succeeds, mocks otherwise (useful for running with no network).

Public APIs carry one-line `///` doc comments throughout.

## Roles

`customer` → `UserShell`, `admin` → `AdminShell`, `superadmin` → `SuperAdminShell` (routed by `AuthGate` from the `users/{uid}.role` field).

- New sign-ups always become `customer`. Admin accounts are created fresh via superadmin **Register Admin** — a customer can never be promoted in place (enforced in UI, datasources, and rules).
- Demoting an admin always asks first, and names outstanding rental dues before proceeding. Superadmin accounts are locked and can never be demoted client-side.
- Denied Firestore reads degrade gracefully: feeds stop loading and show error states instead of hanging or crashing.

## Audit trail

Consequential actions (sign-ups, admin creation, role changes, rental/appointment decisions, inventory edits) are recorded to the `auditLogs` collection via the best-effort `AuditLogger` (logging never blocks the action). Entries are append-only: any signed-in user may write only their own (`actorUid == auth.uid`); only superadmins may read. The Logs tab shows human-readable titles with subject names and `imported` tags.

## Firebase setup

Project: **`ferrer-rental-shop`** (Android + iOS configured via `lib/firebase_options.dart` and `android/app/google-services.json`).

Firestore uses a **named database**: `ferrer-db` (asia-southeast1), referenced in `lib/core/services/app_firestore.dart`. Always use `AppFirestore.instance` — never `FirebaseFirestore.instance` (wrong database).

### One-time console steps (required before first run)

1. **Enable sign-in methods** — in [Authentication](https://console.firebase.google.com/project/ferrer-rental-shop/authentication), enable **Email/Password**. For **Google sign-in**, register the app's SHA-1 (and SHA-256) fingerprints under Project settings → Android app, and set a support email on the OAuth consent screen. Without these, sign-in fails.
2. **Create the superadmin account** — sign up through the app (creates a `customer`), then in the console: Firestore → database `ferrer-db` → `users` collection → open the user's document → change `role` to `superadmin`. That user gets the Superadmin Shell on next launch. Admin accounts are then created from the Accounts tab. Security rules prevent users from ever setting `role` themselves.

### Firestore configuration (already deployed)

- `firestore.rules` — security rules; deployed to the `ferrer-db` database via `firebase.json`.
  - `users`: read own; admin/superadmin read all; sign-up creates own profile with role forced to `customer`; only superadmins may change roles (never to/from `superadmin` client-side, never `customer → admin`).
  - `items` / `itemPhotos`: signed-in read; only admins create/delete/edit — except the `status` field, which signed-in users may flip as part of checkout/cancel flows.
  - `rentals` / `appointments`: users read/create/update only their own docs (create forces `userId == auth.uid`); users may only cancel; admins manage everything; superadmins read everything.
  - `auditLogs`: append-only; create requires `actorUid == auth.uid`; superadmin reads.
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

## Testing

```bash
flutter analyze            # must report no issues
flutter test test/features/auth test/features/superadmin test/features/audit
```

New features and bug fixes follow test-driven development: write the failing test first, watch it fail for the right reason, then implement. (`admin_inbox_test.dart` currently hangs both before and after recent changes — pre-existing issue, unrelated to any pending work.)

## Notes & known limitations

- Item `status` transitions (`available` ↔ `rented`) are performed client-side by the use cases. The rules limit non-admin writes to the `status` field only, but a determined user could still flip availability directly; moving this to a Cloud Function would close that gap.
- The admin dashboard counts users by streaming the whole `users` collection (admin/superadmin-only under the rules). For large user bases, switch to an aggregate `count()` query.
- `MockAuthDataSource` seeds demo accounts (`admin@ferrer.ph`, `maria@example.com`, password `ferrer123`, plus a mock superadmin) for offline development.
