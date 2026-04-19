---
service: "glive-inventory-service"
title: "Third-Party Ticket Purchase"
generated: "2026-03-03"
type: flow
flow_name: "third-party-ticket-purchase"
flow_type: synchronous
trigger: "API request to complete a ticket purchase during customer checkout"
participants:
  - "continuumGrouponWebsite"
  - "continuumGliveInventoryService_httpApi"
  - "continuumGliveInventoryService_schemas"
  - "continuumGliveInventoryService_domainServices"
  - "continuumGliveInventoryService_externalClients"
  - "continuumGliveInventoryService_backgroundJobs"
  - "continuumGliveInventoryWorkers_jobsRunner"
  - "continuumGtxService"
  - "continuumTicketmasterApi"
  - "continuumAxsApi"
  - "continuumTelechargePartner"
  - "continuumProvenuePartner"
  - "continuumGliveInventoryDb"
  - "continuumGliveInventoryRedis"
  - "messageBus"
architecture_ref: "dynamic-third-party-ticket-purchase"
---

# Third-Party Ticket Purchase

## Summary

This flow orchestrates the end-to-end purchase of live-event tickets through a third-party provider. When a customer completes checkout on the Groupon Website, the request flows through GLive Inventory Service which coordinates the purchase across GTX Service (for Groupon transaction management) and the appropriate third-party ticketing provider (Ticketmaster, AXS, Telecharge, or ProVenue). The flow converts an existing reservation into a confirmed purchase, updates inventory counts, and publishes events for downstream consumers. Long-running third-party API calls are offloaded to background jobs to avoid blocking the synchronous API response.

## Trigger

- **Type**: API call (from checkout flow)
- **Source**: Groupon Website (`continuumGrouponWebsite`) via checkout process
- **Frequency**: Per customer purchase -- on demand during active ticket sales

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Groupon Website | Initiates purchase request from customer checkout | `continuumGrouponWebsite` |
| HTTP API Controllers | Receives purchase request, validates, and coordinates | `continuumGliveInventoryService_httpApi` |
| Request/Response Schemas | Validates purchase request payload | `continuumGliveInventoryService_schemas` |
| Domain & Application Services | Orchestrates purchase business logic, updates inventory | `continuumGliveInventoryService_domainServices` |
| External Service Clients | Calls GTX and third-party provider to execute purchase | `continuumGliveInventoryService_externalClients` |
| Background Job Definitions | Defines async job for third-party purchase confirmation | `continuumGliveInventoryService_backgroundJobs` |
| Background Job Runners | Executes third-party purchase jobs asynchronously | `continuumGliveInventoryWorkers_jobsRunner` |
| GTX Service | Manages Groupon transaction lifecycle for the purchase | `continuumGtxService` |
| Third-Party Provider | Executes actual ticket order (varies by provider) | `continuumTicketmasterApi` / `continuumAxsApi` / `continuumTelechargePartner` / `continuumProvenuePartner` |
| GLive Inventory DB | Updates reservation status, order record, inventory counts | `continuumGliveInventoryDb` |
| GLive Inventory Redis | Lock management, cache updates | `continuumGliveInventoryRedis` |
| MessageBus | Receives inventory and availability change events | `messageBus` |

## Steps

1. **Customer initiates purchase**: Groupon Website sends a purchase request to GLive Inventory Service API, referencing an existing reservation.
   - From: `continuumGrouponWebsite`
   - To: `continuumGliveInventoryService_httpApi`
   - Protocol: HTTP/JSON (via Varnish)

2. **Validate purchase request**: HTTP API controller validates the request payload against schemas and verifies the referenced reservation exists and is valid.
   - From: `continuumGliveInventoryService_httpApi`
   - To: `continuumGliveInventoryService_schemas`
   - Protocol: in-process

3. **Delegate to domain service**: Controller delegates to the purchase domain service with validated parameters.
   - From: `continuumGliveInventoryService_httpApi`
   - To: `continuumGliveInventoryService_domainServices`
   - Protocol: in-process

4. **Acquire reservation lock**: Domain service acquires a Redis distributed lock on the reservation to prevent double-purchase.
   - From: `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryRedis`
   - Protocol: TCP (Redis SET NX)

5. **Load reservation from MySQL**: Domain service loads the reservation record and verifies it has not expired or been cancelled.
   - From: `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryDb`
   - Protocol: SQL

6. **Create GTX reservation/purchase**: External client calls GTX Service to create a transaction record for the purchase.
   - From: `continuumGliveInventoryService_externalClients`
   - To: `continuumGtxService`
   - Protocol: HTTP/JSON

7. **Enqueue third-party purchase job**: API controller enqueues a background job for the actual third-party provider order placement to avoid blocking the synchronous response.
   - From: `continuumGliveInventoryService_httpApi`
   - To: `continuumGliveInventoryWorkers_jobsRunner`
   - Protocol: Resque/ActiveJob (via Redis)

8. **Return purchase-in-progress response**: API returns HTTP 202 Accepted with the purchase/order identifier; actual fulfillment continues asynchronously.
   - From: `continuumGliveInventoryService_httpApi`
   - To: `continuumGrouponWebsite`
   - Protocol: HTTP/JSON

9. **Worker executes purchase job**: Background job runner picks up the job, uses external clients to call the third-party provider.
   - From: `continuumGliveInventoryWorkers_jobsRunner`
   - To: `continuumGliveInventoryService_backgroundJobs`
   - Protocol: in-process

10. **Place order with third-party provider**: External client calls the appropriate provider API (based on product partner_type) to place the ticket order.
    - From: `continuumGliveInventoryService_externalClients`
    - To: `continuumTicketmasterApi` / `continuumAxsApi` / `continuumTelechargePartner` / `continuumProvenuePartner`
    - Protocol: HTTP/JSON

11. **Update order and inventory in MySQL**: Domain service updates the reservation to "purchased" status, creates an order record, and adjusts inventory counts (decrement available, increment sold).
    - From: `continuumGliveInventoryService_domainServices`
    - To: `continuumGliveInventoryDb`
    - Protocol: SQL (ActiveRecord transaction)

12. **Invalidate caches**: Redis cache and Varnish HTTP cache are updated/invalidated to reflect new availability.
    - From: `continuumGliveInventoryService_domainServices`
    - To: `continuumGliveInventoryRedis`, `continuumGliveInventoryVarnish`
    - Protocol: TCP, HTTP (PURGE)

13. **Publish inventory event**: Service publishes an availability change event to MessageBus.
    - From: `continuumGliveInventoryWorkers`
    - To: `messageBus`
    - Protocol: STOMP/JMS

14. **Release lock**: Redis distributed lock on the reservation is released.
    - From: `continuumGliveInventoryService_domainServices`
    - To: `continuumGliveInventoryRedis`
    - Protocol: TCP (Redis DEL)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Reservation expired or cancelled | Return HTTP 410 Gone; no purchase attempted | Customer must create a new reservation |
| GTX transaction creation failure | Return HTTP 502; purchase not initiated | Customer retries checkout; reservation still valid |
| Redis lock acquisition timeout | Return HTTP 409 Conflict | Customer retries; prevents double-purchase |
| Third-party provider order failure | Background job retries with backoff; reservation remains in "purchasing" status | Retry up to limit; if exhausted, reservation released and customer notified |
| Third-party provider timeout | Job retries; provider response checked on retry to avoid duplicate orders | Idempotent order check prevents duplicate purchases |
| MySQL transaction failure during inventory update | Transaction rolled back; job retried | Inventory state remains consistent; retry resolves |
| MessageBus publish failure | Logged; purchase is still completed | Downstream consumers may not receive event immediately; MySQL is source of truth |

## Sequence Diagram

```
GrouponWebsite -> HTTPApiControllers: POST /purchase (reservation_id)
HTTPApiControllers -> Schemas: validate purchase request
Schemas --> HTTPApiControllers: valid
HTTPApiControllers -> DomainServices: PurchaseService.call(reservation_id)
DomainServices -> Redis: SET NX lock:reservation:{id}
Redis --> DomainServices: lock acquired
DomainServices -> MySQL: SELECT reservation WHERE id = ?
MySQL --> DomainServices: reservation record
DomainServices -> ExternalClients: create GTX transaction
ExternalClients -> GTXService: POST /reservations
GTXService --> ExternalClients: transaction created
HTTPApiControllers -> ResqueWorkers: enqueue PurchaseJob(reservation_id)
HTTPApiControllers --> GrouponWebsite: HTTP 202 Accepted (order_id)
ResqueWorkers -> BackgroundJobs: execute PurchaseJob
BackgroundJobs -> ExternalClients: place order with provider
ExternalClients -> TicketmasterAPI: POST /orders (or AXS/TC/PV)
TicketmasterAPI --> ExternalClients: order confirmed
BackgroundJobs -> DomainServices: update order status
DomainServices -> MySQL: BEGIN; UPDATE reservation, INSERT order, UPDATE inventory_counts; COMMIT
DomainServices -> Redis: SET cache; PURGE Varnish
DomainServices -> MessageBus: publish availability_change
DomainServices -> Redis: DEL lock:reservation:{id}
```

## Related

- Architecture dynamic view: `dynamic-third-party-ticket-purchase`
- Related flows: [Event Reservation Flow](event-reservation-flow.md), [Ticket Inventory Creation](ticket-inventory-creation.md), [Background Job Processing](background-job-processing.md)
