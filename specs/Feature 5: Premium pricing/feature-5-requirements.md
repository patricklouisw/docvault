## 2) Premium tier architecture (simple now, enforceable later)

You want:

* MVP: everything available to all users while building
* Later: differentiate Free vs Paid features cleanly **without changing your schema** and without creating security holes

This plan uses:

* A **single entitlements source of truth** in `users/{uid}`
* Optional integration with RevenueCat / Stripe later
* Firestore rules that can enforce read/write gates when you flip the switch

---

# A) What “premium” should control (recommended buckets)

### Likely premium candidates for your app

1. **Template access**

* Free: manual packages only (or limited templates)
* Paid: full curated templates, template tasks, template browsing/search

2. **Storage limits**

* Free: limited # of files or total size
* Paid: larger limits

3. **Advanced features**

* Cross-device reminders
* Advanced search
* OCR / AI extraction (future)
* More packages / more documents

You can start with just:

* **Template access gating**
* **Storage quota gating**

---

# B) Data model additions (minimal, stable)

Add an `entitlements` block to `users/{uid}`:

```json
{
  "entitlements": {
    "tier": "free",                 // free | pro
    "features": {
      "templates": true,
      "maxPackages": 999999,
      "maxDocuments": 999999,
      "maxTotalStorageBytes": 5368709120
    },
    "source": "manual",             // manual | revenuecat | stripe
    "validUntil": null              // Timestamp|null (for subscriptions)
  },
  "updatedAt": "Timestamp"
}
```

### Why both tier + features?

* `tier` is easy for UI (“Pro” badge)
* `features` enables fine-grained feature flags without migrations

MVP: set `templates: true` for everyone.

---

# C) Enforcement layers (important)

You need **two layers**:

1. **UI gating** (user experience)
2. **Backend gating** (actual security, via rules or server)

UI gating alone is not secure.

---

# D) UI gating behavior (MVP → Pro-ready)

### Templates tab

* MVP: show it to everyone
* Later: if `templates=false`

  * Replace with paywall screen:

    * “Unlock curated templates”
    * Show preview of what they get

### Create Package screen

* Manual option always available
* Template option:

  * disabled or paywall if no access

### Upload file limits

* Show “Storage used / limit”
* Prevent upload when over limit:

  * show upgrade prompt

---

# E) How to compute storage usage (simple + accurate)

You already store:

* `documents.totalSizeBytes`
  So you can compute total usage by summing across docs.

However, summing every time is expensive.

### Recommended: maintain a per-user usage counter

Add to `users/{uid}`:

```json
{
  "usage": {
    "totalStorageBytes": 123456789,
    "documentsCount": 42,
    "packagesCount": 7
  }
}
```

Update `usage.totalStorageBytes` whenever:

* file uploaded (+size)
* file deleted (-size)

MVP: client-side updates are OK.
Better: Cloud Functions for authoritative tracking later.

---

# F) Firestore Rules enforcement (simple and future-proof)

## 1) Enforce template access (optional when you flip the switch)

Templates are currently public read. If you want templates to be paid-only later, you have two choices:

### Option 1 (recommended): Keep templates readable, gate creation from template

* Templates remain public read-only
* But **creating a package from template** is prevented unless user has entitlement

This avoids complicated template rules and still protects value.

**How?**

* In package create, require:

  * if `mode == "template"` then `users/{uid}.entitlements.features.templates == true`

Firestore rules can check user doc via `get()`.

Example (conceptual):

```js
function canUseTemplates() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.entitlements.features.templates == true;
}
```

Then for packages create:

* If `request.resource.data.mode == "template"` require `canUseTemplates()`

This prevents someone from bypassing the paywall by writing directly to Firestore.

✅ Best approach.

---

## 2) Enforce storage limits (optional later)

At write-time, you can block creating a new file metadata doc if over quota.

But Storage uploads happen before Firestore write sometimes, so you enforce at Firestore “file subdoc create” time and clean up orphan uploads if needed.

Rules could enforce:

* `users/{uid}.usage.totalStorageBytes + newFileSize <= maxTotalStorageBytes`

However, Firestore rules cannot do arithmetic reliably with many complex types, and `usage` could be stale if client is malicious.

### Best practical approach:

* UI enforcement for MVP
* Server enforcement later with Cloud Function “upload finalize” + cleanup

Still: you can add a simple rule gate:

* allow file create only if `entitlements.tier == "pro"` OR file size under a threshold
  But “total usage” enforcement is better on backend.

---

# G) Premium payments integration (future)

Two common approaches:

## Option A: RevenueCat (best for mobile subscriptions)

* Handles Apple/Google receipts
* Webhooks update Firestore entitlements

Flow:

1. User subscribes in app
2. RevenueCat validates purchase
3. Webhook hits Cloud Function
4. Function updates `users/{uid}.entitlements`

## Option B: Stripe (best for web + unified billing)

* Works well if you later add web app
* Requires more integration effort on mobile

For MVP, you can set entitlements manually and later swap `source` to “revenuecat/stripe”.

---

# H) Recommended enforcement strategy (simple + strong)

### MVP (no paywall yet)

* `templates=true` for everyone
* No hard enforcement

### When you launch paid tier:

* Keep templates readable (public)
* Enforce “create package from template” via Firestore rules + UI gating
* Enforce storage via UI first, then backend functions later

---

# I) Acceptance criteria (Premium tier architecture)

* `users/{uid}.entitlements` exists and is read by the app
* UI gates Template-based package creation based on entitlements
* Firestore rules also prevent `mode="template"` package creation if user lacks entitlement (when enabled)
* Usage counters are tracked (at least client-side for MVP)
* No schema changes required later

---

# J) Copy-paste Firestore rules snippet (for later enforcement)

You can keep this disabled until you’re ready to enforce. When ready, add:

```js
function canUseTemplates() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.entitlements.features.templates == true;
}

match /packages/{packageId} {
  allow create: if request.auth != null
    && request.resource.data.ownerId == request.auth.uid
    && (
      request.resource.data.mode != "template"
      || canUseTemplates()
    );
}
```

(Keep your existing read/update/delete rules as-is.)
