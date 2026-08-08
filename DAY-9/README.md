# Sprint 9 — Bringing Business Logic to Life
## E-commerce Product Catalog & Add to Cart (Lightning Web Components)

## Business Problem
What user problem did I solve?

The backend (Apex services, triggers, batch jobs) was already capable — 
it could validate, calculate, and process data — but there was no way for 
a customer to actually see products or add them to a cart. This sprint 
builds the interface layer that lets a customer view active products and 
add items to a cart, without duplicating any business logic in the UI.
productList (parent)
└── productCard (child) — one per product
## Component Architecture
Which components exist? Why?
- **productList** — retrieves products (@wire + Apex), owns shared state 
  (which product is "adding", button labels), handles the Add to Cart 
  action when notified by a child.
- **productCard** — receives one product via @api, displays it, captures 
  the click, and dispatches an addtocart event upward. It does not call 
  Apex itself — it represents a single, independent UI responsibility 
  (a "Job Card" equivalent from the original workbook).

## Data Flow
How does information travel from Salesforce to the screen?
Product__c (Salesforce)
→ ProductController.getActiveProducts() [Apex, @AuraEnabled(cacheable=true)]
→ @wire in productList.js
→ mapped into clean JS properties
→ passed to productCard via @api
→ template displays it
## User Interaction Flow
What happens when Apply (Add to Cart) is clicked? 
Click "Add to Cart" in productCard
→ dispatches CustomEvent('addtocart', { detail: { productId } })
→ productList.handleAddToCart(event) receives it
→ Button shows "Adding..." (disabled)
→ CartController.addToCart(productId, customerId) [imperative Apex]
→ CartService.addToCart()
- finds or creates Cart Order (Status__c = 'Cart')
- checks for existing Order_Item__c for that product
- increments Quantity__c, or inserts new Order_Item__c
→ Success: toast shown, button shows "Added", resets after 2s
→ Failure: friendly error toast, button re-enabled
## Screenshots
Show:
- Eligible Jobs (→ Product List) — `screenshots/product-list-view.png`
- Loading State (→ Adding State) — `screenshots/adding-state.png`
- Application Success (→ Add to Cart Success) — `screenshots/success-state.png`
- Error or Empty State (→ Out of Stock) — `screenshots/out-of-stock-state.png`

## Engineering Decisions
Explain at least three decisions.

1. Eligibility/stock rules remain in Apex (SOQL filters and sort order) 
   so they can be reused by multiple entry points, not just this LWC.
2. Product Card was separated into a child component because it 
   represents an independent UI responsibility — displaying one product.
3. The Add to Cart action uses an imperative Apex call because execution 
   begins from an explicit user action (a click), not a reactive data 
   change.

## Challenges Faced
Describe one genuine debugging problem.

Add to Cart repeatedly failed with FIELD_INTEGRITY_EXCEPTION. Using 
Salesforce Debug Logs, I found that two relationship fields on 
Order_Item__c (Order__c and Product__c) were pointing to Salesforce's 
standard Order and Product objects instead of my custom objects — 
invisible in the UI since both shared the same display label. Fixed by 
deleting and recreating both fields, explicitly selecting the custom 
objects by API name, and verifying with Debug Logs until inserts 
returned Status: Success.

## Learning
What changed in the way I think about user-interface development?

LWC is the visible layer sitting on top of existing architecture — it 
should request actions, not decide business rules. I also learned to 
debug by following Debug Logs to the exact failing field, rather than 
guessing, and that a data-model bug can look identical in the UI while 
behaving completely differently at the API level.
