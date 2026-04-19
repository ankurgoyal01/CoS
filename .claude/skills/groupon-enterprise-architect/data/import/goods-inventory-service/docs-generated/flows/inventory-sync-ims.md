---
service: "goods-inventory-service"
title: "Inventory Sync with IMS"
generated: "2026-03-03"
type: flow
flow_name: "inventory-sync-ims"
flow_type: scheduled
trigger: "Quartz scheduled job and on-demand API trigger"
participants:
  - "continuumGoodsInventoryService_scheduledJobs"
  - "continuumGoodsInventoryService_productAndInventoryServices"
  - "continuumGoodsInventoryService_externalClients"
  - "continuumGoodsInventoryService_inventoryDomainRepositories"
  - "continuumGoodsInventoryService_redisCacheAccess"
  - "continuumGoodsInventoryService_messagingPublishers"
  - "continuumGoodsInventoryService_observability"
  - "continuumGoodsInventoryDb"
  - "continuumGoodsInventoryRedis"
  - "continuumGoodsInventoryMessageBus"
  - "goodsInventoryManagementService"
  - "itemMasterService"
architecture_ref: "dynamic-inventory-sync-ims"
---

# Inventory Sync with IMS

## Summary

This flow synchronizes inventory products and units from the upstream Goods Inventory Management Service (IMS) into GIS. It runs as a scheduled Quartz job and can also be triggered on demand. The sync fetches current warehouse inventory state, reconciles it with GIS local data, creates or updates inventory products and units, backfills item master data, invalidates caches, and publishes inventory change events. This is the primary mechanism by which GIS stays in sync with the physical inventory truth source.

## Trigger

- **Type**: Schedule + manual
- **Source**: Quartz JobScheduler on a cron schedule; also available via admin API for on-demand sync
- **Frequency**: Scheduled (periodic, e.g., hourly or configurable); on-demand as needed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Scheduled Jobs | Triggers the sync job on schedule | `continuumGoodsInventoryService_scheduledJobs` |
| Product & Inventory Services | Orchestrates the sync, reconciliation, and update logic | `continuumGoodsInventoryService_productAndInventoryServices` |
| External Service Clients | Calls IMSClient and ItemMasterClient to fetch upstream data | `continuumGoodsInventoryService_externalClients` |
| Inventory Domain Repositories | Reads current GIS state and persists synced changes | `continuumGoodsInventoryService_inventoryDomainRepositories` |
| Redis Cache Access | Invalidates stale cache entries after sync | `continuumGoodsInventoryService_redisCacheAccess` |
| Inventory Messaging Publishers | Publishes product created/updated events | `continuumGoodsInventoryService_messagingPublishers` |
| Logging & Observability | Logs sync progress, metrics, and errors | `continuumGoodsInventoryService_observability` |
| Goods Inventory Management Service | Upstream inventory data source | `goodsInventoryManagementService` |
| Item Master Service | Supplemental static item data | `itemMasterService` |

## Steps

1. **Trigger sync job**: Quartz scheduler fires the inventory sync job at the configured interval, or an admin triggers it via API.
   - From: `continuumGoodsInventoryService_scheduledJobs`
   - To: `continuumGoodsInventoryService_productAndInventoryServices`
   - Protocol: In-process

2. **Fetch current inventory from IMS**: External Clients call IMSClient to retrieve the latest inventory products and units from the upstream Inventory Management Service.
   - From: `continuumGoodsInventoryService_productAndInventoryServices`
   - To: `continuumGoodsInventoryService_externalClients` (IMSClient)
   - Protocol: HTTP/JSON

3. **Fetch item master data**: For new or updated products, External Clients call ItemMasterClient to retrieve static SKU and item information.
   - From: `continuumGoodsInventoryService_productAndInventoryServices`
   - To: `continuumGoodsInventoryService_externalClients` (ItemMasterClient)
   - Protocol: HTTP/JSON

4. **Load current GIS state**: Inventory Domain Repositories load the current GIS product and unit state for reconciliation.
   - From: `continuumGoodsInventoryService_productAndInventoryServices`
   - To: `continuumGoodsInventoryService_inventoryDomainRepositories`
   - Protocol: JDBI/PostgreSQL

5. **Reconcile and compute deltas**: Product & Inventory Services compare upstream IMS data with local GIS data to determine creates, updates, and quantity adjustments.
   - From: `continuumGoodsInventoryService_productAndInventoryServices`
   - To: `continuumGoodsInventoryService_productAndInventoryServices`
   - Protocol: In-process

6. **Persist changes to database**: Inventory Domain Repositories insert new products/units and update changed records in the PostgreSQL database.
   - From: `continuumGoodsInventoryService_productAndInventoryServices`
   - To: `continuumGoodsInventoryService_inventoryDomainRepositories`
   - Protocol: JDBI/PostgreSQL (transaction)

7. **Invalidate stale caches**: Redis Cache Access invalidates cached projections and pricing for all affected products.
   - From: `continuumGoodsInventoryService_productAndInventoryServices`
   - To: `continuumGoodsInventoryService_redisCacheAccess`
   - Protocol: Redis

8. **Publish inventory change events**: Inventory Messaging Publishers publish InventoryProductCreated and InventoryProductUpdated events for each changed product.
   - From: `continuumGoodsInventoryService_productAndInventoryServices`
   - To: `continuumGoodsInventoryService_messagingPublishers`
   - Protocol: MessageBus

9. **Log sync completion**: Observability components log sync metrics -- products synced, units created/updated, duration, errors.
   - From: `continuumGoodsInventoryService_productAndInventoryServices`
   - To: `continuumGoodsInventoryService_observability`
   - Protocol: Structured logging

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| IMS service unavailable | Retry with backoff; log error; skip sync cycle | GIS serves from existing local data; sync retries next cycle |
| Item Master service unavailable | Proceed with sync but skip item master backfill | Products synced without supplemental item data; backfill on next cycle |
| Database write failure | Transaction rolls back for affected batch; log error | Partially synced; next cycle retries |
| Large delta causing timeout | Batch processing with configurable batch size | Sync processes in chunks; each batch committed independently |
| Stale IMS data (IMS returning outdated info) | GIS trusts IMS as source of truth; reconciliation always overwrites | Local overrides are lost; operational awareness needed |
| Redis invalidation failure | Logged but non-blocking | Stale cache entries expire naturally via TTL |

## Sequence Diagram

```
Quartz Scheduler -> Scheduled Jobs: Fire sync job
Scheduled Jobs -> Product & Inventory Services: triggerInventorySync()
Product & Inventory Services -> External Clients (IMSClient): fetchInventory()
IMSClient -> Goods Inventory Management Service: GET /inventory
Goods Inventory Management Service --> IMSClient: Inventory data
External Clients --> Product & Inventory Services: IMS response
Product & Inventory Services -> External Clients (ItemMasterClient): fetchItemData(skus)
ItemMasterClient -> Item Master Service: GET /items?skus=...
Item Master Service --> ItemMasterClient: Item data
External Clients --> Product & Inventory Services: Item master response
Product & Inventory Services -> Inventory Domain Repositories: loadCurrentState()
Inventory Domain Repositories -> PostgreSQL: SELECT products, units
PostgreSQL --> Inventory Domain Repositories: Current GIS state
Product & Inventory Services -> Product & Inventory Services: reconcile(imsData, gisData)
Product & Inventory Services -> Inventory Domain Repositories: persistChanges(deltas)
Inventory Domain Repositories -> PostgreSQL: BEGIN; INSERT/UPDATE products, units; COMMIT
PostgreSQL --> Inventory Domain Repositories: Success
Product & Inventory Services -> Redis Cache Access: invalidateBatch(productIds)
Redis Cache Access -> Redis: DEL keys
Product & Inventory Services -> Messaging Publishers: publishChanges(events)
Messaging Publishers -> MessageBus: Publish created/updated events
Product & Inventory Services -> Observability: logSyncMetrics(stats)
Product & Inventory Services --> Scheduled Jobs: Sync complete
```

## Related

- Architecture dynamic view: `dynamic-inventory-sync-ims`
- Related flows: [Product Availability Check](product-availability-check.md), [Reservation Creation](reservation-creation.md)
