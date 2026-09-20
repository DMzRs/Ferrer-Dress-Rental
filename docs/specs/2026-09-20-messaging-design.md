# User↔Admin Messaging — Design

Date: 2026-09-20 · Status: approved spec (approach A, all 4 sections signed off in chat)
Related: Ferrer Clothing Rental (`customer` / `admin` roles, no FCM/push infra)

## 1. Goal

In-app text messaging between a customer and the shop (admin side), both
directions. One thread per customer. Text + read state in v1; no push —
messages arrive live while the app is open.

## 2. Decisions (locked in chat)

- Thread model: **one thread per customer** (not per rental/item).
- Entry: **new Messages nav tab on both sides** (customer: 6th, after
  Notifications; admin: 7th, after Reviews).
- V1 scope: **text + read state**. No images, typing indicators, edit/delete.
- Admin identity: **single shared "shop" identity** — the customer sees
  "Ferrer Shop"; any staff member replies. No per-staff attribution in v1.

## 3. Data model (§1 approved)

New collection `conversations`, doc ID = customer `userId` (one thread per
customer by construction):

| Field (thread doc) | Type | Notes |
|---|---|---|
| `userId` | string | owner, forced `== auth.uid` on create |
| `userName` | string | denormalized for the admin inbox |
| `lastText` | string ≤ 120 | preview for inbox rows |
| `lastSenderRole` | string | `customer` or `admin` |
| `updatedAt` | timestamp | bumped per message; inbox sort key |
| `lastSeenCustomer` | timestamp? | stamped when the customer opens the thread |
| `lastSeenAdmin` | timestamp? | stamped when an admin opens the thread |

`conversations/{userId}/messages/{autoId}`:

| Field | Type | Notes |
|---|---|---|
| `senderId` | string | forced `== auth.uid` on create |
| `senderRole` | string | `customer` or `admin`, must match caller |
| `text` | string 1–1000 | length enforced client + rules |
| `createdAt` | timestamp | sort key, asc |

The thread doc is created implicitly by the first message (merge-write, never
blocks sending). `markSeen` is a no-op when the thread doc does not exist yet,
so opening an empty chat never creates junk inbox rows.

Clean-architecture split per existing convention (`lib/features/messaging/`):
`domain/entities` (`Conversation`, `ChatMessage`), `data/models`,
`data/datasources` (`message_data_source.dart`,
`firebase_message_data_source.dart`, `mock_message_data_source.dart`),
`data/repositories` + `domain/repositories`, `domain/usecases`
(`sendMessage`, `watchThread`, `watchInbox`, `markSeen`),
`presentation` (viewmodels + views). New constant
`FirestoreCollections.conversations = 'conversations'`. Mock datasource keeps
in-memory threads/messages, selected by `AppConfig.firebaseEnabled` like
every other feature.

## 4. Rules, indexes (§1 approved)

`firestore.rules` — new blocks following the rentals idiom:

- `match /conversations/{userId}`:
  - `read`: owner (`userId == auth.uid`) or admin.
  - `create/update`: owner writing own thread with `affectedKeys` limited to
    preview fields (`lastText`, `lastSenderRole`, `updatedAt`,
    `lastSeenCustomer`), or admin (any fields).
  - `delete`: admin only.
- `match /conversations/{userId}/messages/{messageId}`:
  - `read`: thread owner or admin.
  - `create`: signed-in, `senderId == auth.uid`, `senderRole` matches caller
    role (customers cannot forge `admin`), `text is string 1..1000`.
  - `update/delete`: admin only (history stays honest; no edits in v1).

Indexes (`firestore.indexes.json`): `conversations(updatedAt DESC)` for the
admin inbox; messages orderBy `createdAt` asc with `limit(50)` + Load-earlier
(no composite index needed — single collection-group queries per thread).
Deploy: `firebase deploy --only firestore:rules,firestore:indexes`.

## 5. Customer UI (§2 approved)

New `Messages` tab (6th destination, after Notifications, before Profile)
showing the thread directly — one thread per customer means no conversation
list on this side, just the chat view:

- Date-grouped bubbles (right rose for own, left cream for shop), timestamps,
  sending/sent states on own messages (server ack — not read receipts, which
  are out of scope).
- Multiline composer (1000 chars) with send button; auto-scroll to latest.
- Empty state: "Questions about a dress or rental? Message the shop here."
- Opening the thread stamps `lastSeenCustomer`, clearing the bubble.

## 6. Admin UI (§3 approved)

New `Messages` tab (7th destination, after Reviews, before Reports): inbox
list of customer threads sorted by `updatedAt` desc — avatar initial, name,
last-message preview, time-ago, unread dot for threads newer than
`lastSeenAdmin`, search-by-name field at top. Tapping opens the thread (same
bubble UI mirrored, own messages labeled "Ferrer Shop"), stamps
`lastSeenAdmin` on open. Long threads paginate with Load-earlier (limit 50).
Admin sends as the shared shop identity.

## 7. Badges, errors, testing (§4 approved)

- Nav bubbles reuse the existing `_NavIcon`/`_QueueIcon` `Badge` pattern
  (count, 9+ cap): customer tab = count of shop messages newer than
  `lastSeenCustomer`; admin tab = count of threads whose last message is from
  the customer and newer than `lastSeenAdmin`. Both derive from
  already-open streams — no extra reads.
- Errors: empty text blocked client-side; failed sends show inline retry on
  the bubble (no snackbar spam); permission-denied maps to the friendly auth
  message.
- Tests: entity/model round-trip, `sendMessage` guards (empty/overlong/
  wrong-role), unread-count math, widget tests for thread rendering + inbox
  filtering; `flutter analyze` + full `flutter test` green.

## 8. Out of scope (explicit)

Push notifications (FCM), photo sharing, typing indicators, per-message read
receipts, message edit/delete, per-staff admin identity. Message docs leave
room for `imageUrl`/`readBy` later; none of the above is precluded.

## 9. File touch list

New: `lib/features/messaging/**` (entities, models, 3 datasources,
repository impl + interface, 4 use cases, 2 viewmodels, thread screen, admin
inbox screen), `test/features/messaging/**`.
Edit: `firestore.rules`, `firestore.indexes.json`,
`lib/core/constants/firestore_collections.dart`,
`lib/features/shell/presentation/views/user_shell.dart` (tab + badge),
`lib/features/admin/admin_shell.dart` (tab + badge), `lib/main.dart`
(repository + use-case providers).
