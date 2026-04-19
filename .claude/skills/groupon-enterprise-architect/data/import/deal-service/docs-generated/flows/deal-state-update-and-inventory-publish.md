---
service: "deal-service"
title: "Deal State Update and Inventory Publish"
generated: "2026-03-02"
type: flow
flow_name: "deal-state-update-and-inventory-publish"
flow_type: asynchronous
trigger: "Single deal ID dequeued from processing_cloud Redis sorted set"
participants:
  - "continuumDealService"
  - "continuumDealManagementApi"
  - "continuumGoodsStoresApi"
  - "salesForce"
  - "continuumDealServicePostgres"
  - "continuumDealServiceMongo"
  - "continuumDealServiceRedisBts"
  - "messageBus"
architecture_ref: "dynamic-deal-state-update-and-inventory-publish"
---

# Deal State Update and Inventory Publish

## Summary

This flow describes per-deal processing: for each deal ID dequeued from `processing_cloud`, the `processDeal` component aggregates data from multiple internal and external APIs, calculates margins and localized pricing, enriches the deal metadata document, persists the results to PostgreSQL and MongoDB, refreshes the BTS Redis cache, and publishes an `INVENTORY_STATUS_UPDATE` event to the message bus if the deal's inventory status has changed. This is the primary data enrichment and propagation flow in deal-service.

## Trigger

- **Type**: event
- **Source**: Deal ID dequeued from `processing_cloud` sorted set by the Deal Processing Cycle
- **Frequency**: Up to 400 times per 5-second cycle (governed by `feature_flags.processDeals.limit` and `feature_flags.processDeals.intervalInSec`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Service Worker (`processDeal`) | Orchestrates the entire per-deal enrichment and persistence sequence | `continuumDealService` |
| Deal Management API (DMAPI) | Provides base deal record and structured deal info | `continuumDealManagementApi` |
| Deal Catalog API | Provides distribution type and marketing info | `externalDealCatalogApi_8b1f` (stub) |
| Goods Stores API | Provides product and supply chain data | `continuumGoodsStoresApi` |
| Geo Services / Bhuvan | Provides geographic division codes for distribution regions | `externalGeoServicesApi_61d4` (stub) |
| Forex API | Provides exchange rates for margin and localized pricing calculations | `externalForexApi_8e03` (stub) |
| Salesforce | Provides margin metadata and historical performance data | `salesForce` |
| M3 Place Read Service | Provides location data for redemption venues | `externalM3PlaceReadApi_2f9b` (stub) |
| M3 Merchant Service | Provides merchant business metadata | `externalM3MerchantServiceApi_9a45` (stub) |
| M3 Google Place API | Provides Google Place attributes for venues | `externalM3GooglePlaceApi_c7b2` (stub) |
| Deal Store Repository (`dealStoreRepository`) | Reads existing deal state; writes updated state | `continuumDealService` |
| Deal Service Postgres | Stores updated deal state, mappings, and mbus update records | `continuumDealServicePostgres` |
| Deal Service MongoDB | Stores enriched deal metadata document | `continuumDealServiceMongo` |
| Deal Service Redis (BTS) | Receives refreshed BTS deal metadata cache entry | `continuumDealServiceRedisBts` |
| Inventory Update Publisher (`inventoryUpdatePublisher`) | Publishes `INVENTORY_STATUS_UPDATE` event if status changed | `continuumDealService` |
| Message Bus | Receives the inventory status update event | `messageBus` |
| Notification Publisher (`notificationPublisher`) | Publishes deal change notification to Redis list | `continuumDealService` |
| Deal Service Redis (Local) | Receives deal change notification via `{event_notification}.message` list | `continuumDealServiceRedisLocal` |

## Steps

1. **Receives deal ID**: `processDeal` component receives a deal ID dequeued from `processing_cloud`.
   - From: Deal Processing Cycle (internal)
   - To: `processDeal`
   - Protocol: in-process

2. **Reads existing deal state**: `dealStoreRepository` reads current deal state from PostgreSQL to compare with the incoming update.
   - From: `continuumDealService`
   - To: `continuumDealServicePostgres`
   - Protocol: Sequelize / TCP

3. **Fetches deal details from DMAPI**: Calls Deal Management API with `DMAPI_CLIENT_ID` to retrieve base deal record.
   - From: `continuumDealService`
   - To: `continuumDealManagementApi`
   - Protocol: REST

4. **Fetches catalog data**: Calls Deal Catalog API with `DEAL_CATALOG_CLIENT_ID` to retrieve distribution type and marketing metadata.
   - From: `continuumDealService`
   - To: `externalDealCatalogApi_8b1f`
   - Protocol: REST

5. **Fetches goods/supply data**: Calls Goods Stores API with `GOODS_STORES_CLIENT_ID` to retrieve product and supply chain data.
   - From: `continuumDealService`
   - To: `continuumGoodsStoresApi`
   - Protocol: REST

6. **Fetches geographic divisions**: Calls Geo Services / Bhuvan with `GEO_SERVICES_CLIENT_ID` to resolve distribution region codes.
   - From: `continuumDealService`
   - To: `externalGeoServicesApi_61d4`
   - Protocol: REST

7. **Fetches exchange rates**: Calls Forex API to obtain current exchange rates for margin and localized pricing calculations.
   - From: `continuumDealService`
   - To: `externalForexApi_8e03`
   - Protocol: REST

8. **Fetches Salesforce data**: Queries Salesforce via jsforce with `SALESFORCE_PASSWORD` credentials for margin metadata and historical performance.
   - From: `continuumDealService`
   - To: `salesForce`
   - Protocol: REST (jsforce)

9. **Fetches venue and merchant data**: In parallel, calls M3 Place Read Service (`M3_PLACES_CLIENT_ID`), M3 Merchant Service (`M3_MERCHANT_SERVICE_CLIENT_ID`), and M3 Google Place API to enrich venue and merchant metadata.
   - From: `continuumDealService`
   - To: `externalM3PlaceReadApi_2f9b`, `externalM3MerchantServiceApi_9a45`, `externalM3GooglePlaceApi_c7b2`
   - Protocol: REST (parallel via `async` library)

10. **Calculates margins and localized pricing**: Uses Forex rates and supply chain data to compute margins and populate `localised_pricing` and `trends` fields.
    - From: `continuumDealService` (in-process calculation)
    - Protocol: in-process

11. **Persists deal state to PostgreSQL**: `dealStoreRepository` upserts updated deal state into `deals` and `product_to_deal_mapping` tables.
    - From: `continuumDealService`
    - To: `continuumDealServicePostgres`
    - Protocol: Sequelize / TCP

12. **Writes enriched metadata to MongoDB**: `dealStoreRepository` upserts the full enriched deal metadata document (including `active`, `ts_updated`, `options`, `trends`, `localised_pricing`, `merchant_recommendations`).
    - From: `continuumDealService`
    - To: `continuumDealServiceMongo`
    - Protocol: MongoDB driver

13. **Refreshes BTS Redis cache**: Writes updated deal metadata to BTS Redis instance.
    - From: `continuumDealService`
    - To: `continuumDealServiceRedisBts`
    - Protocol: Redis

14. **Detects inventory status change**: Compares current deal option active state against the last recorded state in `deal_mbus_updates` (PostgreSQL). If status has changed and `deal_option_inventory_update.mbus_producer.active` is `true`, proceeds to publish.
    - From: `continuumDealService`
    - To: `continuumDealServicePostgres`
    - Protocol: Sequelize

15. **Publishes INVENTORY_STATUS_UPDATE to message bus**: `inventoryUpdatePublisher` generates a UUID, constructs the event payload, and publishes to the topic specified by `deal_option_inventory_update.mbus_producer.topic`.
    - From: `continuumDealService`
    - To: `messageBus`
    - Protocol: nbus-client

16. **Records publish in PostgreSQL**: Inserts or updates a record in `deal_mbus_updates` to track that the event was published.
    - From: `continuumDealService`
    - To: `continuumDealServicePostgres`
    - Protocol: Sequelize

17. **Publishes deal change notification to Redis**: If deal active status changed, `notificationPublisher` pushes a JSON notification to `{event_notification}.message` Redis list.
    - From: `continuumDealService`
    - To: `continuumDealServiceRedisLocal`
    - Protocol: Redis (LPUSH / RPUSH)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DMAPI call fails | Deal cannot be enriched; deal rescheduled into `nodejs_deal_scheduler` with backoff | Deal retried at scheduled timestamp |
| Any upstream REST API call fails | Processing fails for this deal; rescheduled to retry queue | Other deals in the batch continue unaffected |
| PostgreSQL write fails | Persistence error logged; deal may be rescheduled | State update incomplete until retry succeeds |
| MongoDB write fails | Metadata update incomplete; deal rescheduled | State persists in Postgres; MongoDB eventually consistent on retry |
| Message bus publish fails | Failure tracked in `deal_mbus_updates`; event re-attempted on next processing cycle | At-least-once delivery guaranteed via retry |
| `deal_option_inventory_update.mbus_producer.active` = false | Inventory publish step skipped entirely | No event emitted; deal state still updated in stores |

## Sequence Diagram

```
processDeal -> Postgres: read existing deal state
processDeal -> DMAPI: fetch deal details (DMAPI_CLIENT_ID)
DMAPI --> processDeal: deal record
processDeal -> DealCatalogApi: fetch catalog data (DEAL_CATALOG_CLIENT_ID)
processDeal -> GoodsStoresApi: fetch supply data (GOODS_STORES_CLIENT_ID)
processDeal -> GeoServices: fetch region codes (GEO_SERVICES_CLIENT_ID)
processDeal -> ForexApi: fetch exchange rates
processDeal -> Salesforce: query margin metadata (jsforce)
processDeal -> M3PlaceApi: fetch venue data (M3_PLACES_CLIENT_ID)
processDeal -> M3MerchantApi: fetch merchant data (M3_MERCHANT_SERVICE_CLIENT_ID)
processDeal -> M3GooglePlaceApi: fetch Google Place data
processDeal -> processDeal: calculate margins + localized pricing
processDeal -> Postgres: upsert deals + product_to_deal_mapping
processDeal -> MongoDB: upsert deal metadata document
processDeal -> RedisBts: refresh BTS cache
processDeal -> Postgres: read deal_mbus_updates (detect status change)
inventoryUpdatePublisher -> MessageBus: publish INVENTORY_STATUS_UPDATE
processDeal -> Postgres: insert/update deal_mbus_updates
notificationPublisher -> RedisLocal: LPUSH {event_notification}.message
```

## Related

- Architecture dynamic view: `dynamic-deal-state-update-and-inventory-publish`
- Related flows: [Deal Processing Cycle](deal-processing-cycle.md), [Redis Scheduler Retry](redis-scheduler-retry.md), [Deal Notification Publish](deal-notification-publish.md)
