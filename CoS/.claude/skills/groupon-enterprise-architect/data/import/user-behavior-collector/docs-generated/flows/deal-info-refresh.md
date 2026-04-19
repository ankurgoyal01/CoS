---
service: "user-behavior-collector"
title: "Deal Info Refresh"
generated: "2026-03-03"
type: flow
flow_name: "deal-info-refresh"
flow_type: batch
trigger: "Daily cron (update_deal_views) immediately after Spark Event Ingestion step"
participants:
  - "continuumUserBehaviorCollectorJob"
  - "gapiService_5c1a"
  - "continuumDealCatalogService"
  - "visInventoryService_f4b0"
  - "continuumDealInfoRedis"
  - "continuumDealViewNotificationDb"
architecture_ref: "continuumUserBehaviorCollectorJob-components"
---

# Deal Info Refresh

## Summary

The Deal Info Refresh flow enriches deal metadata after the Spark ingestion step completes. It retrieves the set of deal UUIDs present in the `deal_view_notification` database, fetches availability, pricing, options, and inventory data from GAPI (NA or EMEA endpoint), cross-references adult category IDs from the Taxonomy Service, and writes the fully enriched `RedisDealInfo` objects to the `continuumDealInfoRedis` cache for use by downstream notification services.

## Trigger

- **Type**: schedule (sequential step within `update_deal_views` batch job)
- **Source**: Job Orchestrator (`jobOrchestrator`) calls `dealInfoRefresher` after the Spark pipeline completes
- **Frequency**: Daily — runs within the same `update_deal_views` invocation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Job Orchestrator | Triggers the deal info refresh step | `continuumUserBehaviorCollectorJob` |
| Deal Info Refresher | Coordinates fetching, enriching, and caching deal data | `continuumUserBehaviorCollectorJob` (dealInfoRefresher component) |
| Deal View Notification DB | Source of deal UUIDs to refresh | `continuumDealViewNotificationDb` |
| GAPI (api-proxy) | Provides deal availability, pricing, options, and inventory segments | `gapiService_5c1a` |
| Deal Catalog Service | Provides deal catalog data | `continuumDealCatalogService` |
| VIS (Voucher Inventory Service) | Checks voucher inventory availability via `POST /inventory/v1/products/availability` | `visInventoryService_f4b0` |
| Deal Info Redis | Receives enriched deal info objects | `continuumDealInfoRedis` |

## Steps

1. **Fetch deal UUIDs from DB**: Deal Info Refresher calls `getDealIds()` on `AppDataConnection` to retrieve all active deal UUIDs with country information from `continuumDealViewNotificationDb`
   - From: `continuumUserBehaviorCollectorJob` (dealInfoRefresher)
   - To: `continuumDealViewNotificationDb`
   - Protocol: JDBC

2. **Fetch adult category IDs**: Queries Taxonomy Service to retrieve the set of adult-content category IDs for content filtering
   - From: `continuumUserBehaviorCollectorJob` (dealInfoRefresher)
   - To: `continuumTaxonomyService`
   - Protocol: REST

3. **Fetch deal data from GAPI** (per deal): For each deal UUID, calls GAPI with `show=default,categorizations,images,priceSummary,options(inventoryService,availableSegments,schedulerOptions),urgencyMessages` and a 14-day availability window
   - NA endpoint: `GET /v2/deals/{dealID}?client_id=<id>&show=...&locale=...&available_segments_start_at=...&available_segments_end_at=...`
   - EMEA endpoint: `GET /api/mobile/{country}/deals/{dealID}?...`
   - From: `continuumUserBehaviorCollectorJob` (dealInfoRefresher)
   - To: `gapiService_5c1a`
   - Protocol: REST (Retrofit/OkHttp)

4. **Fetch deal catalog data** (as needed): Calls Deal Catalog Service to supplement GAPI data
   - From: `continuumUserBehaviorCollectorJob` (dealInfoRefresher)
   - To: `continuumDealCatalogService`
   - Protocol: REST

5. **Check voucher inventory via VIS**: For relevant deal options, calls `POST /inventory/v1/products/availability` with purchaser UUID and inventory product UUIDs to determine current availability
   - From: `continuumUserBehaviorCollectorJob` (dealInfoRefresher)
   - To: `visInventoryService_f4b0`
   - Protocol: REST (Retrofit/OkHttp)

6. **Build enriched deal object**: Constructs `RedisDealInfo` from GAPI response, catalog data, VIS availability, and adult-category flag

7. **Write enriched deal info to Redis**: Serializes and writes `RedisDealInfo` object to `continuumDealInfoRedis` keyed by deal UUID
   - From: `continuumUserBehaviorCollectorJob` (dealInfoRefresher)
   - To: `continuumDealInfoRedis`
   - Protocol: Redis (Jedis)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GAPI returns non-200 | Logs warning with status code, deal ID, and response headers; returns `Optional.absent()` | Deal info not updated in Redis for that deal; metrics counter incremented |
| GAPI returns null deal body | Returns `null` from `getGapiInfo()` | Deal skipped; no Redis write |
| VIS returns non-200 | Logs at INFO level; returns `false` | Deal not marked as available; processing continues |
| VIS called with empty inventoryProductIds | Logs warning "No inventoryProductIds"; returns `false` | Availability check skipped |
| Redis write fails | No evidence of explicit retry; exception would propagate | Deal info stale in Redis; job may continue or fail depending on exception handling |

## Sequence Diagram

```
JobOrchestrator -> DealInfoRefresher: Trigger deal info refresh
DealInfoRefresher -> DealViewNotificationDb: getDealIds()
DealViewNotificationDb --> DealInfoRefresher: List of DealUuidWithCountry
DealInfoRefresher -> TaxonomyService: Fetch adult category IDs
TaxonomyService --> DealInfoRefresher: Adult category ID set
loop for each deal UUID
  DealInfoRefresher -> GAPI: GET /v2/deals/{dealID} (NA) or /api/mobile/{country}/deals/{dealID} (EMEA)
  GAPI --> DealInfoRefresher: GAPIRawResponseWrapper (or non-200)
  DealInfoRefresher -> DealCatalogService: Fetch catalog data
  DealCatalogService --> DealInfoRefresher: Catalog deal data
  DealInfoRefresher -> VIS: POST /inventory/v1/products/availability
  VIS --> DealInfoRefresher: availability boolean
  DealInfoRefresher -> DealInfoRefresher: Build RedisDealInfo
  DealInfoRefresher -> DealInfoRedis: Write enriched deal object
end
DealInfoRefresher --> JobOrchestrator: Done
```

## Related

- Architecture dynamic view: `continuumUserBehaviorCollectorJob-components`
- Related flows: [Spark Event Ingestion](spark-event-ingestion.md), [Back-in-Stock Update](back-in-stock-update.md)
