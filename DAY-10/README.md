# Sprint 10 – Component Communication, Forms, LDS & Reusable LWC Architecture
### E-Commerce LWC Project

**Reference material:** *Chapter 10 – Building Components That Think Together*
(Sprint 10 – Component Communication, Forms, LDS and Reusable LWC Architecture),
from the Salesforce LWC company-drive-prep workbook. Originally framed around a
"Student Placement Portal"; all concepts and Engineering Sprints (27–31) below have
been re-mapped and applied to this e-commerce project's own objects
(`Product__c`, `Customer__c`, `Order__c`, `Order_Item__c`, etc.).

---

## Component Tree

```
ProductList
│
├── ProductCard   (repeated per product)
│
CustomerProfile    (standalone, LDS-powered)
```

---

## Engineering Sprint Progress

| Sprint (from Chapter 10) | Mapped To | Status |
|---|---|---|
| 27 – Child → Parent events | `ProductCard` → `ProductList` events | Core events working; one known bug (see below) |
| 28 – Profile Form | `CustomerProfile` (LDS form) | Built; not yet fully tested |
| 29 – Reactive Data / Refresh | Profile save → dependent components refresh | Not started |
| 30 – Reusable Empty State | `EmptyState` component | Not started |
| 31 – Final Integration | Full login → profile → browse → cart → order journey | Not started |

---

## Sprint 27 — Component Communication (Parent ↔ Child)

### Parent → Child
`ProductList` fetches active products via Apex (`ProductController.getActiveProducts`) and
passes each one down to `ProductCard` via `@api product`. Per the chapter's principle
*"give a component what it needs"* — the child does not re-fetch data it's already been given.

### Child → Parent (Custom Events)
`ProductCard` dispatches two custom events, each carrying only the minimum data the parent
needs (`productId`):

| Event | Meaning | Type |
|---|---|---|
| `addtocart` | User clicked "Add to Cart" | Intent, not outcome |
| `viewdetails` | User clicked "View Details" | Intent, not outcome |

`ProductList` listens (`onaddtocart`, `onviewdetails`) and decides what to do — the child never
touches parent state directly, per the chapter's *"children report events, parents coordinate
behaviour"* principle.

### Event Contract — Intent vs Outcome
`addtocart` only means "user clicked the button." The parent calls Apex
(`CartController.addToCart`), and only **after** that call succeeds does it update the button
label to "✓ Added" and show a success toast. If the Apex call fails, the button reverts and an
error toast is shown instead — matching the chapter's distinction between *intent* (UI click)
and *outcome* (server-confirmed result).

### Known Issue
The "View Details" flow: the click event fires correctly and `selectedProduct` is confirmed
set in console, but the details panel isn't visibly rendering on the page yet. Root cause not
yet isolated — parked for follow-up.

---

## Sprint 28 — Forms & Lightning Data Service

Built `CustomerProfile` — a profile editing component for `Customer__c` records
(Phone, Email, Address, City, State, Pincode).

**Architecture decision (per the chapter's "Option A / B / C" exercise):** Chose
**Option A — LDS-based record operations**, using `lightning-record-edit-form` +
`lightning-input-field`, instead of custom Apex.

**Why:** This is a straightforward single-record edit with no multi-object business logic —
LDS handles retrieval, update, and standard field validation automatically, so custom Apex
would be unnecessary code (per the chapter's *"use the platform capability when it fits"*
principle).

**Validation split** (per section 10.7 – "Client Validation Is Not Business Security"):
- Client-side: field-level validation from object metadata (e.g. required fields,
  `Pincode__c` as Number) — improves user experience.
- Server-side: Salesforce still enforces things like the unique constraint on `Email__c`
  regardless of what the client does — this remains the authoritative check.

**States handled:** success (`onsuccess` → toast) and error (`onerror` → toast with guidance
to review highlighted fields), per section 10.12's loading/success/error state discipline.

---

## Data Strategy Summary

| Component | Data Source | Why |
|---|---|---|
| ProductList | Apex (`@wire getActiveProducts`) | Needs a filtered/computed product list |
| ProductCard | Passed via `@api` from parent | Avoids duplicate retrieval |
| CustomerProfile | LDS (`lightning-record-edit-form`) | Simple single-record CRUD, no custom logic needed |

---

## Reusability Notes

- `ProductCard` is designed to be reusable across any product-listing context (catalog,
  search results, category pages) since it only depends on the `product` object passed in
  and reports events rather than owning any cart/navigation logic itself.

---
- **Sprint 29:** Ensure dependent components (e.g. delivery/eligibility info) refresh after
  a Customer Profile update, avoiding the "stale data" problem described in section 10.10–10.11.
- **Sprint 30:** Build a reusable `EmptyState` component for empty product lists / empty
  order history screens.
- **Sprint 31:** Wire the full journey end-to-end — login → profile update → product refresh
  → view details → add to cart → order created → order list refresh.

---

## Over View

- **Parent → child:** pass data via `@api` property.
- **Child → parent:** dispatch a `CustomEvent`; parent listens via `on<eventname>`.
- **Why not let a child touch parent state directly?** Keeps components decoupled and
  reusable; the parent stays the single source of truth for its own state.
- **When LDS vs Apex?** LDS for simple single-record CRUD with standard validation; Apex when
  business logic spans multiple objects or needs custom rules.
- **Why is client-side validation not enough?** It only improves UX — a client can be
  bypassed entirely (e.g. a direct API call), so server-side validation remains the actual
  business-integrity check.
- **Sibling-to-sibling communication:** never direct — always coordinated through a common
  parent (or another appropriate shared mechanism).
