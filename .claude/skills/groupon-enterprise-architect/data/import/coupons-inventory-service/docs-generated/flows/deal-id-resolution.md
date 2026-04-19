---
service: "coupons-inventory-service"
title: "Deal ID Resolution"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-id-resolution"
flow_type: asynchronous
trigger: "inventoryProduct.create message on IS Core Message Bus"
participants:
  - "continuumCouponsInventoryMessageBus"
  - "continuumCouponsInventoryService_inventoryProductCreationProcessor"
  - "continuumCouponsInventoryService_dealCatalogClient"
  - "continuumCouponsInventoryService_jdbiInfrastructure"
  - "continuumCouponsInventoryService_redisClient"
architecture_ref: "dynamic-deal-id-resolution"
---

# Deal ID Resolution

## Summary

This asynchronous flow handles the resolution of deal identifiers for newly created inventory products. When the Inventory Product Creation Processor receives an `inventoryProduct.create` event from the IS Core Message Bus, it calls the Deal Catalog Service to look up associated deal ids, updates the product record in Postgres with the resolved deal ids, and caches the deal-id lists in Redis by created date for efficient subsequent queries.

## Trigger

- **Type**: event
- **Source**: `inventoryProduct.create` message published by the Message Bus Publisher after product creation
- **Frequency**: per product creation event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| IS Core Message Bus | Delivers the inventoryProduct.create message to the processor | `continuumCouponsInventoryMessageBus` |
| Inventory Product Creation Processor | Consumes the event, orchestrates deal-id resolution, DB update, and cache write | `continuumCouponsInventoryService_inventoryProductCreationProcessor` |
| Deal Catalog Client | HTTP client that calls the Deal Catalog Service to resolve deal ids | `continuumCouponsInventoryService_dealCatalogClient` |
| Jdbi Persistence Infrastructure | Updates product records with resolved deal ids and reads product created date | `continuumCouponsInventoryService_jdbiInfrastructure` |
| Redis Client | Caches deal-id lists by created date | `continuumCouponsInventoryService_redisClient` |

## Steps

1. **Receive creation event**: The IS Core Message Bus delivers an inventoryProduct.create message to the Inventory Product Creation Processor via Mbus subscription.
   - From: `continuumCouponsInventoryMessageBus`
   - To: `continuumCouponsInventoryService_inventoryProductCreationProcessor`
   - Protocol: Mbus subscription

2. **Look up deal ids**: The processor calls the Deal Catalog Client to resolve deal identifiers for the inventory product.
   - From: `continuumCouponsInventoryService_inventoryProductCreationProcessor`
   - To: `continuumCouponsInventoryService_dealCatalogClient`
   - Protocol: HTTP/JSON

3. **Update product in database**: The processor updates the product record in Postgres with the resolved deal ids and reads the product created date.
   - From: `continuumCouponsInventoryService_inventoryProductCreationProcessor`
   - To: `continuumCouponsInventoryService_jdbiInfrastructure`
   - Protocol: Jdbi

4. **Cache deal ids in Redis**: The processor caches the resolved deal-id list in Redis, keyed by the product's created date, for efficient subsequent queries.
   - From: `continuumCouponsInventoryService_inventoryProductCreationProcessor`
   - To: `continuumCouponsInventoryService_redisClient`
   - Protocol: Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog Service unavailable | HTTP client timeout or connection error | Message processing fails; standard Mbus retry behavior applies |
| Deal Catalog returns no deal ids | Product may not have a corresponding deal yet | Product remains without deal-id; may be retried on next message or manual intervention |
| Database update failure | Jdbi throws exception | Message processing fails; Mbus retry applies; deal-id not persisted |
| Redis cache write failure | Cache write fails; non-blocking for data integrity | Deal-id persisted in DB but not cached; cache populated on next query |
| Malformed message | Message deserialization fails | Message discarded or sent to error handling; logged for investigation |

## Sequence Diagram

```
IS Core Message Bus -> Inventory Product Creation Processor: inventoryProduct.create message
Inventory Product Creation Processor -> Deal Catalog Client: lookupDealIds(productId)
Deal Catalog Client -> Deal Catalog Service: GET /deals?productId={id}
Deal Catalog Service --> Deal Catalog Client: deal ids
Deal Catalog Client --> Inventory Product Creation Processor: deal ids
Inventory Product Creation Processor -> Jdbi Infrastructure: UPDATE product SET deal_ids = ? WHERE id = ?
Jdbi Infrastructure --> Inventory Product Creation Processor: updated
Inventory Product Creation Processor -> Jdbi Infrastructure: SELECT created_date FROM product WHERE id = ?
Jdbi Infrastructure --> Inventory Product Creation Processor: created_date
Inventory Product Creation Processor -> Redis Client: cacheDealIds(createdDate, dealIds)
Redis Client --> Inventory Product Creation Processor: cached
```

## Related

- Architecture component view: `components-continuum-coupons-inventory-service`
- Related flows: [Product Creation](product-creation.md) (upstream trigger), [Product Query by Deal ID](product-query-by-deal-id.md) (downstream consumer of cached deal-ids)
