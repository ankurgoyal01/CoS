---
service: "glive-inventory-service"
title: "Ticket Inventory Creation"
generated: "2026-03-03"
type: flow
flow_name: "ticket-inventory-creation"
flow_type: synchronous
trigger: "API request to create a new ticket product (POST /glive/v1/products or /glive/v2/products)"
participants:
  - "continuumGliveInventoryService_httpApi"
  - "continuumGliveInventoryService_schemas"
  - "continuumGliveInventoryService_domainServices"
  - "continuumGliveInventoryService_externalClients"
  - "continuumGliveInventoryDb"
  - "continuumGliveInventoryRedis"
  - "continuumGliveInventoryVarnish"
  - "messageBus"
architecture_ref: "dynamic-ticket-inventory-creation"
---

# Ticket Inventory Creation

## Summary

This flow handles the creation of a new ticket product in the GLive Inventory Service. When an operator (via the Admin UI) or an internal service submits a product creation request, the API validates the payload against schemas, delegates to domain services which persist the product and events to MySQL, sync inventory data with the appropriate third-party ticketing provider, invalidate Varnish cache entries, and publish an inventory status event to MessageBus for downstream consumers.

## Trigger

- **Type**: API call
- **Source**: GLive Inventory Admin (`continuumGliveInventoryAdmin`) or internal service
- **Frequency**: On demand -- when new live-event ticket products are onboarded

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API Controllers | Receives the product creation request, validates input | `continuumGliveInventoryService_httpApi` |
| Request/Response Schemas | Validates JSON request body structure | `continuumGliveInventoryService_schemas` |
| Domain & Application Services | Orchestrates product creation business logic (CreateProductService, UpdateProductEventsService) | `continuumGliveInventoryService_domainServices` |
| External Service Clients | Calls third-party provider to verify/sync inventory | `continuumGliveInventoryService_externalClients` |
| GLive Inventory DB | Persists the new product, events, and inventory counts | `continuumGliveInventoryDb` |
| GLive Inventory Redis | Cache updated with new product data; locks used during creation | `continuumGliveInventoryRedis` |
| GLive Inventory Varnish | Cache invalidated for affected inventory/availability endpoints | `continuumGliveInventoryVarnish` |
| MessageBus | Receives inventory status update event | `messageBus` |

## Steps

1. **Receive product creation request**: Admin UI or internal service sends POST to `/glive/v1/products` or `/glive/v2/products` with product details (name, partner type, events, pricing).
   - From: `continuumGliveInventoryAdmin` or upstream consumer
   - To: `continuumGliveInventoryService_httpApi`
   - Protocol: HTTP/JSON

2. **Validate request payload**: HTTP API controller uses schema objects to validate the request body structure and required fields.
   - From: `continuumGliveInventoryService_httpApi`
   - To: `continuumGliveInventoryService_schemas`
   - Protocol: in-process

3. **Delegate to domain service**: Controller calls CreateProductService (or equivalent domain service) with validated parameters.
   - From: `continuumGliveInventoryService_httpApi`
   - To: `continuumGliveInventoryService_domainServices`
   - Protocol: in-process

4. **Acquire distributed lock**: Domain service acquires a Redis lock to prevent concurrent product creation conflicts.
   - From: `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryRedis`
   - Protocol: TCP (Redis SET NX)

5. **Persist product and events to MySQL**: Domain service creates the product record, associated event records, initial inventory counts, and pricing in a database transaction.
   - From: `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryDb`
   - Protocol: SQL (ActiveRecord transaction)

6. **Sync with third-party provider**: External client calls the appropriate ticketing provider API (Ticketmaster, AXS, Telecharge, or ProVenue based on partner_type) to verify or synchronize inventory data.
   - From: `continuumGliveInventoryService_externalClients`
   - To: `continuumTicketmasterApi` / `continuumAxsApi` / `continuumTelechargePartner` / `continuumProvenuePartner`
   - Protocol: HTTP/JSON

7. **Update cache**: Domain service writes new product data to Redis cache.
   - From: `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryRedis`
   - Protocol: TCP (Redis SET)

8. **Invalidate Varnish cache**: Domain service sends HTTP PURGE request to Varnish to clear stale inventory/availability cache entries.
   - From: `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryVarnish`
   - Protocol: HTTP (PURGE)

9. **Publish inventory event**: Service publishes an inventory status update event to MessageBus for downstream consumers.
   - From: `continuumGliveInventoryService`
   - To: `messageBus`
   - Protocol: STOMP/JMS

10. **Release lock and return response**: Redis lock is released and the API returns the created product with HTTP 201.
    - From: `continuumGliveInventoryService_domainServices`
    - To: `continuumGliveInventoryRedis` (lock release) / `continuumGliveInventoryService_httpApi` (response)
    - Protocol: TCP / in-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Schema validation failure | Return HTTP 422 with error details | Product not created; client notified of validation errors |
| MySQL transaction failure | Rollback transaction; release lock | Product not created; client receives HTTP 500 |
| Third-party provider sync failure | Log error; product created in local DB with pending sync status | Product created locally; background job scheduled to retry sync |
| Redis lock acquisition timeout | Return HTTP 409 Conflict | Client should retry after delay |
| Varnish PURGE failure | Log warning; continue | Product created; cache may serve stale data until TTL expires |
| MessageBus publish failure | Log error; continue | Product created; downstream consumers may not receive event immediately |

## Sequence Diagram

```
AdminUI -> HTTPApiControllers: POST /glive/v1/products
HTTPApiControllers -> Schemas: validate request body
Schemas --> HTTPApiControllers: validation result
HTTPApiControllers -> DomainServices: CreateProductService.call(params)
DomainServices -> Redis: SET NX lock:product:create
Redis --> DomainServices: lock acquired
DomainServices -> MySQL: BEGIN; INSERT products, events, inventory_counts; COMMIT
MySQL --> DomainServices: product persisted
DomainServices -> ExternalClients: sync with provider API
ExternalClients -> TicketmasterAPI: POST /events (or equivalent)
TicketmasterAPI --> ExternalClients: sync confirmation
ExternalClients --> DomainServices: sync result
DomainServices -> Redis: SET product cache
DomainServices -> Varnish: PURGE /inventory/v1/availability
DomainServices -> MessageBus: publish inventory_status_update
DomainServices -> Redis: DEL lock:product:create
DomainServices --> HTTPApiControllers: created product
HTTPApiControllers --> AdminUI: HTTP 201 Created + product JSON
```

## Related

- Architecture dynamic view: `dynamic-ticket-inventory-creation`
- Related flows: [Event Reservation Flow](event-reservation-flow.md), [Background Job Processing](background-job-processing.md)
