---
service: "goods-inventory-service"
title: "Reverse Fulfillment"
generated: "2026-03-03"
type: flow
flow_name: "reverse-fulfillment"
flow_type: synchronous
trigger: "API request to cancel exported inventory units"
participants:
  - "continuumGoodsInventoryService_apiControllers"
  - "continuumGoodsInventoryService_apiMappers"
  - "continuumGoodsInventoryService_reverseFulfillmentService"
  - "continuumGoodsInventoryService_externalClients"
  - "continuumGoodsInventoryService_inventoryDomainRepositories"
  - "continuumGoodsInventoryService_redisCacheAccess"
  - "continuumGoodsInventoryService_messagingPublishers"
  - "continuumGoodsInventoryDb"
  - "continuumGoodsInventoryRedis"
  - "continuumGoodsInventoryMessageBus"
  - "srsOutboundController"
  - "goodsStoresService"
architecture_ref: "dynamic-reverse-fulfillment"
---

# Reverse Fulfillment

## Summary

This flow handles the cancellation of exported inventory units -- units that have already been committed to an order and potentially handed off to the shipping pipeline. The Reverse Fulfillment Service coordinates with SRS Outbound Controller to cancel units in the shipping system, with Goods Stores Service to apply add-back logic (returning units to available inventory), updates the local GIS database, and publishes cancellation events. This is a critical flow for handling order cancellations, returns, and inventory corrections.

## Trigger

- **Type**: API call
- **Source**: Order management services, customer support tools, or automated cancellation rules
- **Frequency**: On demand, per cancellation request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers | Receives reverse fulfillment request | `continuumGoodsInventoryService_apiControllers` |
| API Mappers & Validators | Validates cancellation payload | `continuumGoodsInventoryService_apiMappers` |
| Reverse Fulfillment Service | Orchestrates the multi-system cancellation flow | `continuumGoodsInventoryService_reverseFulfillmentService` |
| External Service Clients | Calls SRSClient and GoodsStoresClient | `continuumGoodsInventoryService_externalClients` |
| Inventory Domain Repositories | Updates unit statuses in PostgreSQL | `continuumGoodsInventoryService_inventoryDomainRepositories` |
| Redis Cache Access | Invalidates cache after cancellation | `continuumGoodsInventoryService_redisCacheAccess` |
| Inventory Messaging Publishers | Publishes cancellation events | `continuumGoodsInventoryService_messagingPublishers` |
| SRS Outbound Controller | Cancels units in the shipping pipeline | `srsOutboundController` |
| Goods Stores Service | Applies add-back logic to return inventory | `goodsStoresService` |

## Steps

1. **Receive reverse fulfillment request**: Cancellation request with inventory unit ID(s), order reference, and cancellation reason.
   - From: `Order Management / Support`
   - To: `continuumGoodsInventoryService_apiControllers`
   - Protocol: REST/HTTP

2. **Validate cancellation request**: API Mappers validate unit IDs exist, are in a cancellable state (exported), and cancellation reason is provided.
   - From: `continuumGoodsInventoryService_apiControllers`
   - To: `continuumGoodsInventoryService_apiMappers`
   - Protocol: In-process

3. **Load inventory units and verify eligibility**: Reverse Fulfillment Service loads the target units from the database and confirms they are eligible for cancellation.
   - From: `continuumGoodsInventoryService_reverseFulfillmentService`
   - To: `continuumGoodsInventoryService_inventoryDomainRepositories`
   - Protocol: JDBI/PostgreSQL

4. **Cancel units in SRS**: External Clients call SRSClient to cancel the exported units in the outbound shipping controller.
   - From: `continuumGoodsInventoryService_reverseFulfillmentService`
   - To: `continuumGoodsInventoryService_externalClients` (SRSClient)
   - Protocol: HTTP/JSON

5. **Apply add-back logic via Goods Stores**: External Clients call GoodsStoresClient to determine if cancelled units should be returned to available inventory (add-back) based on store and gateway rules.
   - From: `continuumGoodsInventoryService_reverseFulfillmentService`
   - To: `continuumGoodsInventoryService_externalClients` (GoodsStoresClient)
   - Protocol: HTTP/JSON

6. **Update unit statuses in GIS**: Transition the inventory units from exported to cancelled (or back to available if add-back applies) in the database.
   - From: `continuumGoodsInventoryService_reverseFulfillmentService`
   - To: `continuumGoodsInventoryService_inventoryDomainRepositories`
   - Protocol: JDBI/PostgreSQL (transaction)

7. **Invalidate Redis cache**: Invalidate cached projections for affected products so availability reflects the cancelled/returned units.
   - From: `continuumGoodsInventoryService_reverseFulfillmentService`
   - To: `continuumGoodsInventoryService_redisCacheAccess`
   - Protocol: Redis

8. **Publish cancellation events**: Publish inventory unit cancellation events to the message bus for downstream consumers (fulfillment tracking, analytics, goods stores).
   - From: `continuumGoodsInventoryService_reverseFulfillmentService`
   - To: `continuumGoodsInventoryService_messagingPublishers`
   - Protocol: MessageBus

9. **Return cancellation response**: Return confirmation of the reverse fulfillment operation with unit statuses and add-back results.
   - From: `continuumGoodsInventoryService_apiMappers`
   - To: `Order Management / Support`
   - Protocol: REST/HTTP (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Units not in cancellable state | Return 409 Conflict with current unit status | Caller must handle non-cancellable units |
| SRS cancellation failure | Log error; partial cancellation may proceed for non-shipped units | Shipped units cannot be cancelled; return error for those units |
| Goods Stores add-back failure | Log warning; proceed with cancellation without add-back | Units are cancelled but not returned to available pool; manual intervention needed |
| Database update failure | Transaction rolls back; no state change | Return 500; caller retries |
| Partial failure (some units cancelled, some failed) | Return partial success response with per-unit status | Caller handles individual unit results |
| MessageBus publish failure | Logged; non-blocking | Downstream consumers may miss cancellation event; Cronus snapshots provide backup |

## Sequence Diagram

```
Order Management -> API Controllers: POST /inventory-units/reverse-fulfill
API Controllers -> API Mappers: Validate request
API Mappers --> API Controllers: Validated request
API Controllers -> Reverse Fulfillment Service: reverseFulfill(unitIds, reason)
Reverse Fulfillment Service -> Inventory Domain Repositories: loadUnits(unitIds)
Inventory Domain Repositories -> PostgreSQL: SELECT units WHERE status=exported
PostgreSQL --> Inventory Domain Repositories: Exported units
Reverse Fulfillment Service -> External Clients (SRSClient): cancelExportedUnits(unitIds)
SRSClient -> SRS Outbound Controller: Cancel units
SRS Outbound Controller --> SRSClient: Cancellation confirmed
External Clients --> Reverse Fulfillment Service: SRS result
Reverse Fulfillment Service -> External Clients (GoodsStoresClient): evaluateAddBack(unitIds)
GoodsStoresClient -> Goods Stores Service: Check add-back eligibility
Goods Stores Service --> GoodsStoresClient: Add-back decision
External Clients --> Reverse Fulfillment Service: Add-back result
Reverse Fulfillment Service -> Inventory Domain Repositories: updateUnits(cancelled/available)
Inventory Domain Repositories -> PostgreSQL: BEGIN; UPDATE units; COMMIT
PostgreSQL --> Inventory Domain Repositories: Success
Reverse Fulfillment Service -> Redis Cache Access: invalidateProjection(productId)
Reverse Fulfillment Service -> Messaging Publishers: publishCancellationEvent(event)
Messaging Publishers -> MessageBus: Publish event
Reverse Fulfillment Service --> API Controllers: ReverseFulfillmentResult
API Controllers -> API Mappers: mapToResponse(result)
API Controllers --> Order Management: 200 OK (JSON)
```

## Related

- Architecture dynamic view: `dynamic-reverse-fulfillment`
- Related flows: [Order Fulfillment](order-fulfillment.md), [Reservation Creation](reservation-creation.md)
