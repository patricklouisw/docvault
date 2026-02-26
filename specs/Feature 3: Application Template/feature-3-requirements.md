# 📦 Feature 3 — Package Application System with CRUD + Templates + Auto-Matching

This feature defines the full **Application Package System**, including:

* Browse Templates (read-only)
* View Template Details
* Create Package (Manual or From Template)
* Copy Template Tasks into Package
* Auto-match tasks with uploaded documents
* Manually add tasks
* Update package
* Delete package
* Track progress

This feature integrates with:

* Feature 1 (Documents + Encryption)
* Feature 2 (Authentication + Vault Unlock)

---

# 🎯 Feature 3 Scope

Users can:

1. Browse system-defined templates
2. View template details
3. Create application package manually
4. Create application package from template
5. Automatically generate tasks from template
6. Auto-complete tasks based on uploaded documents
7. Add manual tasks
8. Link/unlink documents to tasks
9. Track progress
10. Edit and delete packages

---

# 1️⃣ Data Model Used

---

## Templates (System Data — Read Only)

### templates/{templateId}

```json
{
  "name": "Spousal Sponsorship (Canada)",
  "summary": "...",
  "countryCode": "CA",
  "countryName": "Canada",
  "jurisdictionLevel": "federal",
  "publisher": "IRCC",
  "applicationType": "permanent_residence",
  "categoryId": "immigration",
  "subcategoryIds": ["permanent_residence", "family_sponsorship"],
  "tags": ["spouse", "PR"],
  "searchTokens": ["canada", "spousal"],
  "isActive": true,
  "accessTier": "free",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

---

### templates/{templateId}/tasks/{taskId}

```json
{
  "title": "Passport or travel document",
  "groupName": "Identity and civil status",
  "required": true,
  "expectedSubcategoryId": "passport",
  "order": 10
}
```

Templates are:

* Public read-only
* Cannot be edited by user
* Used only to create packages

---

# 2️⃣ Template UX

---

## A) Templates List Screen

Displays:

* Search bar
* List of active templates
* Filter by:

  * Country
  * Category
  * Application type (optional MVP)

Each card shows:

* Template name
* Country
* Publisher
* Short summary

Tap → Template Detail

---

## B) Template Detail Screen

Displays:

* Summary
* Eligibility
* Required documents
* Resources
* Steps to apply

Button at bottom:

→ **Create Package From Template**

---

# 3️⃣ Package Data Model (User Data)

---

## packages/{packageId}

```json
{
  "ownerId": "uid",
  "title": "Spousal Sponsorship - My Application",
  "mode": "template",
  "templateId": "ca_ircc_spousal_sponsorship_pr",
  "categoryId": "immigration",
  "subcategoryId": "family_sponsorship",
  "status": "draft",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

`mode`:

* "manual"
* "template"

`status`:

* "draft"
* "submitted"
* "archived"

---

## packages/{packageId}/tasks/{taskId}

```json
{
  "title": "Passport or travel document",
  "groupName": "Identity and civil status",
  "required": true,
  "expectedSubcategoryId": "passport",
  "status": "missing",
  "documentId": null,
  "fileId": null,
  "source": "template",
  "order": 10,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

---

# 4️⃣ Packages List Screen

Displays:

* All packages for user
* Sorted by updatedAt desc

Each card shows:

* Title
* Status
* Category
* Progress (X of Y completed)

FAB → Create Package

---

# 5️⃣ Create Package Flow

---

## Step 1 — Choose Mode

Two options:

* Manual Package
* From Template

---

# 6️⃣ Manual Package Creation (CRUD — Create)

User inputs:

* Title
* Category
* Subcategory

Create:

```json
{
  "mode": "manual",
  "templateId": null,
  "status": "draft"
}
```

No tasks created automatically.

User adds tasks manually later.

---

# 7️⃣ Template-Based Package Creation

---

## Step 1 — User selects template

Fetch:

* template document
* template tasks

---

## Step 2 — Create package doc

```json
{
  "mode": "template",
  "templateId": "<selected_template>",
  "status": "draft"
}
```

---

## Step 3 — Copy Template Tasks

For each template task:

Create package task with:

* source = "template"
* status = "missing"
* documentId = null
* fileId = null
* Copy title, groupName, required, expectedSubcategoryId, order

Use batch write.

---

# 8️⃣ Auto-Matching Logic (Core Intelligence)

After package creation:

1. Fetch all user documents
2. For each package task:

   * If task.expectedSubcategoryId == document.subcategoryId
   * Mark task complete
   * Set documentId

Matching logic:

```text
task.expectedSubcategoryId == document.subcategoryId
```

Country is not included in MVP matching.

---

# 9️⃣ Task-Level CRUD

---

## A) Add Manual Task

User can add:

* Title
* Group name (optional)
* Required (true/false)

Create:

* source = "manual"
* status = "missing"
* expectedSubcategoryId = null

---

## B) Link Document to Task

User selects document manually.

Update:

* status = "complete"
* documentId = selected doc
* fileId optional

---

## C) Unlink Document

Set:

* status = "missing"
* documentId = null
* fileId = null

---

# 🔟 Package Detail Screen

Displays:

* Title
* Status
* Progress bar
* Task list grouped by groupName

Each task shows:

* Checkbox
* Required badge
* Linked document name (if complete)

---

## Progress Calculation

```text
progress = completedTasks / totalTasks
```

---

# 1️⃣1️⃣ Update Package (CRUD — Update)

Editable:

* Title
* Status

Status change to submitted:

* No validation required in MVP

---

# 1️⃣2️⃣ Delete Package (CRUD — Delete)

Delete:

* packages/{packageId}
* all subcollection tasks

No effect on documents.

---

# 1️⃣3️⃣ Auto-Complete Hook from Feature 1

Whenever document uploaded:

* Find tasks where:

  * expectedSubcategoryId == document.subcategoryId
  * status == "missing"
  * ownerId == auth.uid
* Mark complete
* Set documentId

---

# 1️⃣4️⃣ Security Rules (Feature 3)

Templates:

```javascript
match /templates/{templateId} {
  allow read: if true;
  allow write: if false;

  match /tasks/{taskId} {
    allow read: if true;
    allow write: if false;
  }
}
```

Packages:

```javascript
match /packages/{packageId} {
  allow read, write: if request.auth != null
    && request.auth.uid == resource.data.ownerId;

  match /tasks/{taskId} {
    allow read, write: if request.auth != null
      && request.auth.uid ==
        get(/databases/$(database)/documents/packages/$(packageId)).data.ownerId;
  }
}
```

---

# 1️⃣5️⃣ Acceptance Criteria (Feature 3 Complete When)

* User can browse templates
* User can view template details
* User can create manual package
* User can create package from template
* Template tasks copied correctly
* Tasks auto-match existing documents
* Uploading new document auto-completes tasks
* User can manually add tasks
* User can link/unlink documents
* User can update package
* User can delete package
* Progress indicator updates correctly
