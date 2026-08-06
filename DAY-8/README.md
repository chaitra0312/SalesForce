# Asynchronous Apex (E-Commerce Order Management System)

## Overview
This sprint focused on identifying which parts of a business transaction must run
immediately (synchronously) and which parts can safely run in the background
(asynchronously). All four asynchronous Apex mechanisms — **Future Methods**,
**Queueable Apex**, **Batch Apex**, and **Scheduled Apex** — were implemented and
tested against a custom E-Commerce data model built on Salesforce.

## Business Context
The system manages online orders end-to-end: order placement, shipment tracking,
payments, and customer records. When a customer places an order, only the
essential steps (stock check, order creation, inventory update, confirmation)
happen in the main transaction. Everything else — courier sync, notifications,
analytics, cleanup of unpaid orders — happens in the background so the customer
is never kept waiting.

## Custom Objects Used
| Object | API Name |
|---|---|
| Order | `Order__c` |
| Order Item | `Order_Item__c` |
| Product | `Product__c` |
| Customer | `Customer__c` |
| Payment | `Payment__c` |
| Shipment | `Shipment__c` |
| Category | `Category__c` |

## Classes Implemented

### 1. `OrderPostProcessingJob` (Queueable)
Runs after an order is saved. Creates a `Shipment__c` record (status `Packed`)
and prepares notification/analytics work in the background, without delaying
order confirmation to the customer.

### 2. `ShippingPartnerSyncJob` → `OrderNotificationJob` (Queueable Chaining)
Demonstrates one background job triggering another. `ShippingPartnerSyncJob`
syncs the order with an external courier (simulated), updates the shipment to
`Shipped`, and — only on success — enqueues `OrderNotificationJob` to notify
the customer. Prevents sending "shipped" notifications for failed syncs.

### 3. `LegacyShippingNotifier` (Future Method)
Reference implementation of the older `@future(callout=true)` pattern, kept to
demonstrate understanding of legacy asynchronous code encountered in existing
Salesforce orgs. Not rewritten to Queueable without business justification.

### 4. `CustomerTierBatch` (Batch Apex)
Recalculates `Premium_Customer__c` on every `Customer__c` record based on
lifetime order spend (`SUM(Total_Amount__c) >= 50000`). Batches by customer
(not by order) so each customer's full order history is aggregated correctly
within a single batch scope.

### 5. `UnpaidOrderCancelBatch` + `UnpaidOrderScheduler` (Scheduled + Batch)
Every night at 1:00 AM, `UnpaidOrderScheduler` triggers `UnpaidOrderCancelBatch`,
which finds all orders with `Payment_Status__c = 'Pending'` older than 24 hours
and marks them `Status__c = 'Cancelled'`. Demonstrates the common pattern of
Scheduled Apex (deciding *when*) launching Batch Apex (handling *how much*).

## Design Decisions
- **Minimal state passed to async jobs** — only record `Id`s are passed into
  Queueable jobs; fresh data is re-queried at execution time since the
  underlying record may have changed by the time the job runs.
- **Single responsibility per job** — shipment sync, notifications, and
  analytics are kept in separate jobs rather than one large Queueable class.
- **Idempotency awareness** — considered what happens if a sync job runs
  twice (duplicate shipment/notification) and how status fields can guard
  against it.
- **Bulkification maintained** — no SOQL or DML inside loops, even inside
  asynchronous contexts (Batch `execute` and Queueable `execute`).
- **Standard Apex used for time-sensitive validation** (e.g. promo code
  checks) — asynchronous tools were intentionally *not* used where the user
  needs an immediate answer.

## Testing & Verification
All jobs were manually triggered via the Developer Console's Execute Anonymous
window and verified using:

```apex
List<AsyncApexJob> jobs = [
    SELECT Id, JobType, Status, NumberOfErrors, ExtendedStatus
    FROM AsyncApexJob
    ORDER BY CreatedDate DESC LIMIT 10
];
for (AsyncApexJob j : jobs) {
    System.debug(j.JobType + ' | ' + j.Status + ' | Errors: ' + j.NumberOfErrors);
}
```

All jobs completed with **Status = Completed** and **0 errors**.

## How to Run
1. Deploy all seven Apex classes to a Salesforce org with the E-Commerce
   objects listed above.
2. Ensure at least one `Order__c` record exists, linked to a `Customer__c`.
3. In Developer Console → Debug → Open Execute Anonymous Window, run:

```apex
Order__c o = [SELECT Id FROM Order__c LIMIT 1];
System.enqueueJob(new OrderPostProcessingJob(o.Id));
System.enqueueJob(new ShippingPartnerSyncJob(o.Id));
Database.executeBatch(new CustomerTierBatch(), 200);
System.schedule('Unpaid Order Cleanup', '0 0 1 * * ?', new UnpaidOrderScheduler());
```

4. Check results via the `AsyncApexJob` query above, and inspect updated
   `Shipment__c` and `Customer__c` records.

## Key Takeaway
Asynchronous Apex is not chosen because it "sounds advanced" — it is chosen
because the workload's nature (background-safe, large-volume, or time-based)
demands a different execution model. Governor Limits, bulkification, and
single-responsibility design still apply fully inside asynchronous contexts.
