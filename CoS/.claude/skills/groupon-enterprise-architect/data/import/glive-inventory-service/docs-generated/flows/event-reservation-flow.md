---
service: "glive-inventory-service"
title: "Event Reservation Flow"
generated: "2026-03-03"
type: flow
flow_name: "event-reservation-flow"
flow_type: synchronous
trigger: "API request to create a ticket reservation (POST /glive/v1/reservations or /glive/v2/reservations)"
participants:
  - "continuumGliveInventoryService_httpApi"
  - "continuumGliveInventoryService_schemas"
  - "continuumGliveInventoryService_domainServices"
  - "continuumGliveInventoryService_externalClients"
  - "continuumGliveInventoryDb"
  - "continuumGliveInventoryRedis"
  - "continuumGliveInventoryVarnish"
  - "continuumTicketmasterApi"
  - "continuumAxsApi"
  - "messageBus"
architecture_ref: "dynamic-event-reservation-flow"
---

# Event Reservation Flow

## Summary

This flow handles the creation and management of ticket reservations. When a customer or internal process requests tickets for a live event, GLive Inventory Service creates a reservation that holds inventory for a time-limited period. The service acquires a distributed lock, validates availability, creates a hold with the third-party ticketing provider, persists the reservation to MySQL, updates Redis cache and Varnish, and publishes an availability change event. Reservations have an expiry time; if not converted to a purchase, they are automatically released (via background job or TTL) and inventory is restored.

## Trigger

- **Type**: API call
- **Source**: Groupon Website (`continuumGrouponWebsite`) during add-to-cart or checkout initiation, or GLive Inventory Admin for manual reservations
- **Frequency**: Per customer ticket selection -- on demand during active event sales

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API Controllers | Receives reservation request and returns reservation details | `continuumGliveInventoryService_httpApi` |
| Request/Response Schemas | Validates reservation request JSON structure | `continuumGliveInventoryService_schemas` |
| Domain & Application Services | Orchestrates reservation logic: availability check, hold creation, persistence | `continuumGliveInventoryService_domainServices` |
| External Service Clients | Calls third-party provider to create a hold on tickets | `continuumGliveInventoryService_externalClients` |
| GLive Inventory DB | Persists reservation record and updates inventory counts | `continuumGliveInventoryDb` |
| GLive Inventory Redis | Distributed lock, cache update, reservation expiry tracking | `continuumGliveInventoryRedis` |
| GLive Inventory Varnish | Cache invalidated for availability endpoint | `continuumGliveInventoryVarnish` |
| Third-Party Provider | Creates a ticket hold in the external system | `continuumTicketmasterApi` / `continuumAxsApi` (or TC/PV) |
| MessageBus | Receives availability change event | `messageBus` |

## Steps

1. **Receive reservation request**: Consumer (Groupon Website or Admin UI) sends POST to `/glive/v1/reservations` or `/glive/v2/reservations` with product ID, event ID, quantity, and optional seat preferences.
   - From: `continuumGrouponWebsite` / `continuumGliveInventoryAdmin`
   - To: `continuumGliveInventoryService_httpApi`
   - Protocol: HTTP/JSON

2. **Validate request payload**: HTTP API controller validates the JSON request against schema objects.
   - From: `continuumGliveInventoryService_httpApi`
   - To: `continuumGliveInventoryService_schemas`
   - Protocol: in-process

3. **Delegate to domain service**: Controller calls the reservation domain service.
   - From: `continuumGliveInventoryService_httpApi`
   - To: `continuumGliveInventoryService_domainServices`
   - Protocol: in-process

4. **Acquire distributed lock**: Domain service acquires a Redis lock scoped to the product/event to serialize concurrent reservation requests for the same inventory.
   - From: `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryRedis`
   - Protocol: TCP (Redis SET NX with TTL)

5. **Check availability in MySQL**: Domain service queries current inventory counts to verify sufficient available tickets.
   - From: `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryDb`
   - Protocol: SQL

6. **Create hold with third-party provider**: External client calls the appropriate provider API to create a ticket hold/reservation in the external system.
   - From: `continuumGliveInventoryService_externalClients`
   - To: `continuumTicketmasterApi` / `continuumAxsApi` / `continuumTelechargePartner` / `continuumProvenuePartner`
   - Protocol: HTTP/JSON

7. **Persist reservation to MySQL**: Domain service creates a reservation record with status "active", sets expiry timestamp, and adjusts inventory counts (decrement available, increment reserved) in a transaction.
   - From: `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryDb`
   - Protocol: SQL (ActiveRecord transaction)

8. **Update Redis cache and set expiry tracker**: Cache is updated with new availability data; a Redis key with TTL is set for reservation expiry tracking.
   - From: `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryRedis`
   - Protocol: TCP (Redis SET, SETEX)

9. **Invalidate Varnish cache**: HTTP PURGE sent to Varnish for the affected availability endpoints.
   - From: `continuumGliveInventoryService_domainServices`
   - To: `continuumGliveInventoryVarnish`
   - Protocol: HTTP (PURGE)

10. **Publish availability change event**: Service publishes an availability change event to MessageBus.
    - From: `continuumGliveInventoryService`
    - To: `messageBus`
    - Protocol: STOMP/JMS

11. **Release lock and return response**: Redis lock is released; API returns HTTP 201 with reservation details including reservation ID, expiry time, and hold reference.
    - From: `continuumGliveInventoryService_domainServices` / `continuumGliveInventoryService_httpApi`
    - To: `continuumGliveInventoryRedis` (lock release) / consumer (HTTP response)
    - Protocol: TCP / HTTP/JSON

### Reservation Expiry (Asynchronous)

12. **Expiry detection**: Background job or Redis key expiry callback detects that a reservation has passed its expiry time without being converted to a purchase.
    - From: `continuumGliveInventoryWorkers_jobsRunner`
    - To: `continuumGliveInventoryRedis`
    - Protocol: TCP

13. **Release reservation**: Domain service updates reservation status to "expired", restores inventory counts (increment available, decrement reserved), and releases the hold with the third-party provider.
    - From: `continuumGliveInventoryService_domainServices`
    - To: `continuumGliveInventoryDb`, `continuumGliveInventoryService_externalClients`
    - Protocol: SQL, HTTP/JSON

14. **Update caches and publish event**: Varnish and Redis caches invalidated; availability change event published to MessageBus.
    - From: `continuumGliveInventoryService_domainServices`
    - To: `continuumGliveInventoryVarnish`, `continuumGliveInventoryRedis`, `messageBus`
    - Protocol: HTTP, TCP, STOMP/JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Insufficient availability | Return HTTP 409 Conflict with availability details | No reservation created; customer informed |
| Third-party hold creation failure | Rollback MySQL changes; release lock; return HTTP 502 | No reservation; customer should retry |
| Redis lock acquisition timeout | Return HTTP 409 Conflict | Customer retries; prevents overselling |
| MySQL transaction failure | Rollback; release third-party hold if created; release lock | Consistent state; customer retries |
| Varnish PURGE failure | Log warning; continue | Reservation created; cached availability may briefly be stale |
| Reservation expiry job failure | Job retried via Resque retry mechanism | Reservation eventually expired; brief period of held-but-unreleasable inventory |

## Sequence Diagram

```
Consumer -> HTTPApiControllers: POST /glive/v1/reservations
HTTPApiControllers -> Schemas: validate request body
Schemas --> HTTPApiControllers: valid
HTTPApiControllers -> DomainServices: ReservationService.create(params)
DomainServices -> Redis: SET NX lock:event:{event_id}
Redis --> DomainServices: lock acquired
DomainServices -> MySQL: SELECT inventory_counts WHERE event_id = ?
MySQL --> DomainServices: availability data
DomainServices -> ExternalClients: create hold with provider
ExternalClients -> TicketmasterAPI: POST /holds (or AXS/TC/PV equivalent)
TicketmasterAPI --> ExternalClients: hold_reference
ExternalClients --> DomainServices: hold created
DomainServices -> MySQL: BEGIN; INSERT reservation; UPDATE inventory_counts; COMMIT
DomainServices -> Redis: SET cache; SETEX reservation:expiry:{id}
DomainServices -> Varnish: PURGE /inventory/v1/availability/{product_id}
DomainServices -> MessageBus: publish availability_change
DomainServices -> Redis: DEL lock:event:{event_id}
DomainServices --> HTTPApiControllers: reservation details
HTTPApiControllers --> Consumer: HTTP 201 Created (reservation JSON)
```

## Related

- Architecture dynamic view: `dynamic-event-reservation-flow`
- Related flows: [Third-Party Ticket Purchase](third-party-ticket-purchase.md), [Ticket Inventory Creation](ticket-inventory-creation.md), [Background Job Processing](background-job-processing.md)
