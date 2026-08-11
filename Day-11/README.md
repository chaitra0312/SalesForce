# Sprint 11 – Crossing the Salesforce Boundary
### External Integration: Shipment Sync, Coupon Validation & Nightly Stock Sync

This sprint extends the Placement/E-commerce Salesforce application to communicate with
external systems — moving from a self-contained Salesforce app to one that safely crosses
the Salesforce boundary.

---

## 1. Business Problem

Our e-commerce system doesn't handle deliveries itself — a third-party courier partner does.
Until now, Salesforce had no way to notify that courier when an order shipped, no way to verify
a coupon code against a live external validation service, and no way to receive nightly stock
updates from a warehouse partner. All of this required Salesforce to safely "leave the building"
and talk to systems it does not control.

This sprint implements three real integration patterns to solve that:

| Task | Business Need | Pattern Used |
|---|---|---|
| 1 & 2 | Notify courier when a shipment is created, and recover automatically if that notification fails | Asynchronous callout + Retry |
| 3 | Validate a coupon code live while the customer waits | Synchronous callout |
| 4 | Pull nightly stock updates from a warehouse partner for all active products | Scheduled + Batch Apex |

---

## 2. External System

For this sprint, a **mock API** (`https://httpbin.org`) was used in place of a real courier/
warehouse system, since no real external service was available. httpbin simply echoes back
whatever is sent to it and returns standard HTTP status codes — enough to prove out request
building, response handling, error handling, retries, and idempotency, exactly as a real
integration would require.

> **Note:** This is explicitly a mock integration for learning purposes. All patterns
> (Named Credential, error handling, retry classification) are written the same way they
> would be against a real production endpoint — only the URL would change.

---

## 3. Data Flow

### Task 1 & 2 — Shipment Sync (Asynchronous)
```
Shipment__c created
   ↓
ShipmentSyncQueueable (Queueable Apex)
   ↓
Named Credential (Courier_API)
   ↓
HTTP POST /post → External Courier API
   ↓
Response processed → Integration_Status__c updated
   ↓
If "Retry Required" → ShipmentRetryBatch picks it up later
```

### Task 3 — Coupon Validation (Synchronous)
```
User enters coupon code in couponValidator LWC
   ↓
Apex (CouponValidationService.validateCoupon) — called live, no queue
   ↓
HTTP POST → External Validation API
   ↓
Response returned immediately to LWC
   ↓
Result displayed to user in real time
```

### Task 4 — Nightly Stock Sync (Scheduled + Batch)
```
NightlyStockSyncScheduler fires at 2:00 AM daily
   ↓
Database.executeBatch(NightlyStockSyncBatch)
   ↓
For each Product__c (in chunks): callout → get stock update → update record
   ↓
Batch completes, failures logged individually (not batch-wide)
```

---

## 4. Authentication

A **Named Credential** (`Courier_API`) was configured with:
- URL: `https://httpbin.org`
- Identity Type: Anonymous
- Authentication Protocol: No Authentication

No credentials, tokens, or secrets are hardcoded anywhere in Apex. All callouts reference
`callout:Courier_API/...` — if the real courier's authentication method changes, only the
Named Credential config changes, not a single line of Apex.

In a production scenario with a real authenticated API, this would instead use an
**Auth Provider** + OAuth-based Named Credential, without any change to the callout code itself.

---

## 5. Error Handling

Every callout distinguishes between response types rather than treating all failures the same:

| Response | Meaning | Action Taken |
|---|---|---|
| 200 | Success | `Integration_Status__c = Sent`, external ID stored |
| 401 / 403 | Authentication/authorisation failure | `Integration_Status__c = Failed` (needs admin attention, not a retry) |
| 500+ | External server error | `Integration_Status__c = Retry Required` (likely temporary) |
| Timeout (CalloutException) | External system too slow | `Integration_Status__c = Retry Required` |
| Other unexpected status | Unrecognised | `Integration_Status__c = Failed`, logged for review |

This distinction was validated against real failures during testing — the mock API returned
both a timeout and a live 503 error during development, and both were correctly classified as
"Retry Required" rather than a permanent failure.

---

## 6. Retry Strategy

`ShipmentRetryBatch` runs as a **Batch Apex** job that:
1. Queries all `Shipment__c` records where `Integration_Status__c = 'Retry Required'`
2. Re-submits each one through the same `ShipmentSyncQueueable` used for the original attempt

This keeps the retry logic identical to the original attempt logic — no duplicated code path,
no risk of the retry behaving differently than the first try.

In production, this batch would itself be triggered by a **Scheduled Apex** job (same pattern
as `NightlyStockSyncScheduler`) running every few hours, rather than manually.

---

## 7. Idempotency

Duplicate sends are prevented with a status check at the very top of `ShipmentSyncQueueable.execute()`:

```apex
if (shp.Integration_Status__c == 'Sent') {
    System.debug('Shipment ' + shp.Name + ' already synced. Skipping duplicate send.');
    return;
}
```

Because this guard lives inside the Queueable itself (not just the retry batch), it protects
against duplicates **no matter what triggers the send** — manual execution, the retry batch, or
a future automated trigger. This was verified by manually re-running the sync on an already-
"Sent" record and confirming the callout was skipped (visible in the debug log).

---

## 8. Integration Pattern: Point-to-Point vs Middleware

This sprint uses **point-to-point** integration — Salesforce calls the external API directly,
with no middleware layer in between. This is appropriate here because there is currently only
one external system involved (the mock courier/stock API).

If the number of external systems grows (e.g., separate courier, payment gateway, SMS provider,
and warehouse systems all needing integration), a **middleware** layer (such as MuleSoft) would
become more appropriate — centralising transformation, routing, and monitoring instead of
maintaining several independent point-to-point integrations.

---

## 9. Synchronous vs Asynchronous — Why Each Was Chosen

| Integration | Sync or Async | Why |
|---|---|---|
| Shipment sync to courier | **Asynchronous** (Queueable) | The customer placing an order doesn't need to wait for courier notification — it's a secondary effect, not part of the core transaction |
| Coupon validation | **Synchronous** (direct Apex call from LWC) | The customer is actively waiting for an answer before they can proceed with checkout — an immediate response is required |
| Nightly stock sync | **Scheduled + Batch (Asynchronous)** | Thousands of product records processed on a timer, with no user waiting at all — this must run in the background, in chunks, safely within governor limits |

---

## 10. Components Built

| File | Type | Purpose |
|---|---|---|
| `ShipmentSyncQueueable.cls` | Apex (Queueable) | Async shipment sync + idempotency guard |
| `ShipmentRetryBatch.cls` | Apex (Batch) | Finds and re-attempts failed/retry-required shipments |
| `CouponValidationService.cls` | Apex (`@AuraEnabled`) | Synchronous coupon validation for LWC |
| `couponValidator` | LWC | UI for live coupon validation |
| `NightlyStockSyncBatch.cls` | Apex (Batch + Callouts) | Nightly per-product stock sync via callout |
| `NightlyStockSyncScheduler.cls` | Apex (Schedulable) | Triggers the nightly batch on a cron schedule |
| Named Credential: `Courier_API` | Config | Secure endpoint reference, no hardcoded secrets |
| `Shipment__c` fields | Custom fields | `Integration_Status__c`, `External_Shipment_Id__c`, `Last_Sync_Attempt__c`, `Integration_Error__c` |

---

## 11. How to Test

**Manual shipment sync:**
```apex
Id shipmentId = 'YOUR_SHIPMENT_ID';
System.enqueueJob(new ShipmentSyncQueueable(shipmentId));
```

**Manual retry sweep:**
```apex
Database.executeBatch(new ShipmentRetryBatch(), 5);
```

**Coupon validation:** Add the `couponValidator` component to any App/Record/Home page via
Lightning App Builder, enter a code, click Apply.

**Nightly stock sync (manual test):**
```apex
Database.executeBatch(new NightlyStockSyncBatch(), 5);
```

**Schedule the nightly job (one-time setup):**
```apex
String cronExpr = '0 0 2 * * ?'; // 2:00 AM daily
System.schedule('Nightly Stock Sync', cronExpr, new NightlyStockSyncScheduler());
```

---

## 12. What This Sprint Demonstrates

- Building an API contract before writing code
- Making secure Apex HTTP callouts using Named Credentials (no hardcoded secrets)
- Choosing synchronous vs asynchronous integration based on business need, not convenience
- Designing for real-world failure: timeouts, server errors, and authentication failures
- Implementing idempotency to prevent duplicate external records
- Implementing retry logic using Batch Apex
- Scheduling recurring background integration jobs with Scheduled Apex
- Separating Salesforce's own business truth (the order/shipment exists) from external
  synchronisation status (whether the courier was successfully notified) — these are two
  independent facts that must be tracked separately, not conflated
