---
service: "glive-gia"
title: "Invoice Creation and Payment"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "invoice-creation-and-payment"
flow_type: asynchronous
trigger: "Admin user triggers invoice creation for a deal via the GIA UI"
participants:
  - "continuumGliveGiaWebApp"
  - "continuumGliveGiaWorker"
  - "continuumGliveGiaRedisCache"
  - "continuumGliveGiaMysqlDatabase"
  - "continuumAccountingService"
architecture_ref: "dynamic-glive-gia-invoice-payment"
---

# Invoice Creation and Payment

## Summary

When a GrouponLive deal is ready for merchant settlement, an operations admin triggers invoice creation in GIA. The web app validates the request and enqueues an async Resque job. The background worker then creates the invoice and payment records in GIA's MySQL database and pushes corresponding vendor and payment entries to the Accounting Service to maintain the financial ledger. Invoice state transitions (e.g., issued, paid) are tracked via a state machine and audited via Paper Trail.

## Trigger

- **Type**: user-action (synchronous initiation) + asynchronous processing
- **Source**: Admin submits `POST /deals/:id/invoices` in the GIA web UI
- **Frequency**: On-demand per deal

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GIA Web App | Receives admin request; validates; enqueues async job | `continuumGliveGiaWebApp` |
| GIA Redis | Holds the invoice creation Resque job | `continuumGliveGiaRedisCache` |
| GIA Background Worker | Creates invoice and payment records; calls Accounting Service | `continuumGliveGiaWorker` |
| GIA MySQL Database | Stores invoice and payment records | `continuumGliveGiaMysqlDatabase` |
| Accounting Service | External financial ledger; receives vendor/payment creation requests | `continuumAccountingService` |

## Steps

1. **Admin requests invoice creation**: Admin submits `POST /deals/:id/invoices` in the GIA UI
   - From: Admin browser
   - To: `continuumGliveGiaWebApp` (`gliveGia_webControllers`)
   - Protocol: REST (HTTP POST)

2. **Validate deal eligibility**: `businessServices` checks that the deal is in an invoiceable state (e.g., not already invoiced, events are settled)
   - From: `continuumGliveGiaWebApp` (`businessServices`)
   - To: `continuumGliveGiaMysqlDatabase`
   - Protocol: ActiveRecord / MySQL

3. **Enqueue invoice creation job**: `jobEnqueuer` pushes an async Resque job to Redis to handle invoice creation and Accounting Service calls
   - From: `continuumGliveGiaWebApp` (`jobEnqueuer`)
   - To: `continuumGliveGiaRedisCache`
   - Protocol: Resque / Redis

4. **Respond to admin**: Controller returns success response and redirects admin to invoices list
   - From: `continuumGliveGiaWebApp`
   - To: Admin browser
   - Protocol: HTTP 302

5. **Worker dequeues job**: `resqueWorkers_GliGia` pulls the invoice creation job from Redis
   - From: `continuumGliveGiaWorker`
   - To: `continuumGliveGiaRedisCache`
   - Protocol: Resque / Redis

6. **Create invoice record in MySQL**: `jobServices_GliGia` creates the invoice record via `workerDomainModels`; state machine sets initial state to `issued`; Paper Trail records the creation event
   - From: `continuumGliveGiaWorker` (`jobServices_GliGia` -> `workerDomainModels`)
   - To: `continuumGliveGiaMysqlDatabase`
   - Protocol: ActiveRecord / MySQL

7. **Create payment record in MySQL**: A corresponding payment record is created, linked to the invoice
   - From: `continuumGliveGiaWorker` (`jobServices_GliGia` -> `workerDomainModels`)
   - To: `continuumGliveGiaMysqlDatabase`
   - Protocol: ActiveRecord / MySQL

8. **Push entries to Accounting Service**: `workerRemoteClients_GliGia` calls the Accounting Service to create vendor payment records in the financial ledger
   - From: `continuumGliveGiaWorker` (`workerRepositories_GliGia` -> `workerRemoteClients_GliGia`)
   - To: `continuumAccountingService`
   - Protocol: REST

9. **Update invoice state on success**: On Accounting Service success, `workerDomainModels` transitions the invoice state to `submitted`
   - From: `continuumGliveGiaWorker` (`jobServices_GliGia`)
   - To: `continuumGliveGiaMysqlDatabase`
   - Protocol: ActiveRecord / MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal not in invoiceable state | Validation error returned before enqueue | Invoice not created; admin sees validation error |
| Accounting Service unavailable | Resque job fails; retried by Resque | Invoice record may exist in MySQL without Accounting Service entry; manual reconciliation may be needed |
| Duplicate invoice creation attempt | Business service or DB unique constraint prevents duplicate | Admin sees error; existing invoice remains intact |
| MySQL write failure | ActiveRecord exception; job fails and is retried | Invoice not created; retried on next Resque cycle |

## Sequence Diagram

```
Admin -> GIA Web App: POST /deals/:id/invoices
GIA Web App -> GIA MySQL Database: SELECT deal (validate state)
GIA MySQL Database --> GIA Web App: deal data
GIA Web App -> GIA Redis: RPUSH invoice_creation job
GIA Web App --> Admin: 302 redirect to invoices list
GIA Background Worker -> GIA Redis: LPOP invoice_creation job
GIA Background Worker -> GIA MySQL Database: INSERT invoices (state: issued)
GIA Background Worker -> GIA MySQL Database: INSERT payments
GIA Background Worker -> Accounting Service: POST /vendor_payments
Accounting Service --> GIA Background Worker: 201 Created
GIA Background Worker -> GIA MySQL Database: UPDATE invoices SET state = 'submitted'
```

## Related

- Architecture dynamic view: `dynamic-glive-gia-invoice-payment`
- Related flows: [Uninvoiced Deal Detection](uninvoiced-deal-detection.md), [Deal Creation from DMAPI](deal-creation-from-dmapi.md)
