## 1) Expiration tracking + notification system (MVP-friendly, zero-knowledge safe)

You already store:

* `documents/{docId}.dates.expiresAt`
* `documents/{docId}.countryCode/countryName`
  That’s enough to build expiration tracking + reminders without touching encrypted file contents.

---

# A) What we’re building

### User-facing

* “Expiring soon” section on Documents tab (or a new “Alerts” screen)
* Optional push notifications:

  * “Your Passport expires in 30 days”
  * “Police certificate expires in 7 days” (if applicable)
* Per-document reminder settings (optional MVP)

### Admin-facing (allowed)

* Only aggregate stats (counts), not document content.
* Admin can see “how many docs have expiry set” but not decrypt anything.

---

# B) Data model additions

## Option 1 (simplest): store reminder settings on each document (recommended)

Add to `documents/{docId}`:

```json
{
  "dates": {
    "issuedAt": "Timestamp|null",
    "expiresAt": "Timestamp|null"
  },
  "reminders": {
    "enabled": true,
    "daysBefore": [90, 30, 7, 1],
    "lastNotifiedAt": {
      "90": "Timestamp|null",
      "30": "Timestamp|null",
      "7": "Timestamp|null",
      "1": "Timestamp|null"
    }
  }
}
```

* `daysBefore` determines which reminders user wants.
* `lastNotifiedAt` prevents duplicate notifications.

If you want less bloat, you can store only:

* `enabled`
* `daysBefore`
  and track dedupe in a separate notifications collection (below).

---

## Option 2 (more scalable): add a notifications subcollection (optional)

`users/{uid}/notifications/{notificationId}`

```json
{
  "type": "document_expiring",
  "documentId": "doc_123",
  "daysBefore": 30,
  "scheduledFor": "Timestamp",
  "sentAt": "Timestamp|null",
  "status": "scheduled" // scheduled | sent | cancelled
}
```

This is more work, but provides a clean audit trail and avoids putting `lastNotifiedAt` map in the document.

For MVP: **Option 1 is enough.**

---

# C) UI requirements

## 1) Documents list: “Expiring soon” section

* Show docs with expiresAt within next 90 days
* Sort by expiresAt ascending
* Display:

  * Title
  * Country
  * Expiry date
  * “Expires in X days” label
* If expiresAt is null: do not include

## 2) Document detail: Reminder settings

In Document Detail screen:

* Toggle: “Remind me before expiry”
* Multi-select chips (90/30/7/1 days) or a single dropdown preset
* Save to Firestore

---

# D) Backend scheduling approach (3 options)

## Option A — On-device reminders only (fastest MVP)

* Use local notifications on the device
* Schedule notifications locally based on expiresAt
* Works even if user is offline
* Downsides: reminders don’t sync across devices

✅ Best for early MVP if you don’t want server complexity.

---

## Option B — Cloud Scheduler + Cloud Functions (recommended if you want cross-device + consistent)

1. Cloud Scheduler runs daily (e.g., 9:00 AM user local time is hard; start with UTC daily)
2. Function queries Firestore for expiring docs and sends push notifications via FCM

**Challenge:** Firestore querying by expiresAt requires indexes and efficient querying.

### How to query efficiently (without scanning everything)

Add a field on document:

* `expiresOnDay` = `YYYY-MM-DD` string (derived from expiresAt)
  or
* `expiresAt` with range queries

Then the job can query:

* `expiresAt` between now and now+90 days

But per-user timezone scheduling is harder. MVP can notify in a fixed time window.

✅ Good for later MVP+.

---

## Option C — Hybrid (best UX)

* Server sends “you have expiring documents” generic notification
* Device opens app and shows the list
* Or local scheduling per device for exact day/time

---

# E) Indexes you’ll need (if using server queries)

For showing expiring soon in-app (client-side query):

* Query `documents` by `ownerId == uid` AND `dates.expiresAt >= now` order by `dates.expiresAt`

Firestore needs composite index for:

* `ownerId` + `dates.expiresAt`

---

# F) Implementation rules & behavior

## Expiring soon calculation

* `daysLeft = ceil((expiresAt - now)/1 day)`
* Categories:

  * Expired: daysLeft < 0
  * Expiring soon: 0–30
  * Upcoming: 31–90

## Edge cases

* expiresAt missing → ignore
* expiresAt in past → show “Expired” badge
* user edits expiry date → reschedule reminders (local) or reset `lastNotifiedAt` map keys (server)

---

# G) Security + privacy notes

* Expiry reminders require only metadata (expiresAt, title/subcategory).
* No encryption changes required.
* Admin still cannot decrypt any file content.

---

# H) Acceptance criteria (Expiration system)

* User can set issue/expiry (already in Feature 1)
* App shows “Expiring soon” section correctly
* User can enable/disable reminders per document
* App prevents duplicate notifications (via `lastNotifiedAt` or notifications collection)
* Works without accessing encrypted file contents
