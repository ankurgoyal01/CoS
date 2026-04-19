---
service: "mds"
title: "Deal Enrichment Pipeline"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-enrichment-pipeline"
flow_type: asynchronous
trigger: "Deal Processing Worker dequeues a deal identifier from the Redis processing queue"
participants:
  - "continuumMarketingDealService"
  - "continuumMarketingDealDb"
  - "continuumMarketingDealServiceRedis"
  - "continuumDealCatalogService"
  - "continuumDealManagementApi"
  - "continuumM3PlacesService"
  - "continuumM3MerchantService"
  - "continuumBhuvanService"
  - "continuumPricingService"
  - "continuumSmaMetrics"
  - "salesForce"
  - "messageBus"
architecture_ref: "dynamic-mds-deal-enrichment"
---

# Deal Enrichment Pipeline

## Summary

The deal enrichment pipeline is the core data processing flow in MDS. When a deal identifier is dequeued from the Redis processing queue, the Deal Processing Worker acquires a distributed lock and orchestrates a multi-step enrichment sequence. The pipeline fetches catalog metadata, taxonomy classifications, pricing/margin data, redemption locations, merchant/place data, geo/division data, performance metrics, and CRM attributes from upstream services, computes deltas against the existing deal record, persists updates to PostgreSQL, and publishes deal-change notifications and inventory status updates to downstream consumers via the message bus and Redis notification queues.

## Trigger

- **Type**: event (dequeued from Redis processing queue)
- **Source**: Deal Processing Worker (`mdsDealProcessingWorker`) dequeues a deal identifier that was placed in the queue by the Deal Event Consumption flow or by the Deal Change Tracking & Publish Worker
- **Frequency**: Per deal event; hundreds to thousands per day depending on deal update volume

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Processing Worker | Orchestrates fetch/update flow, manages retries/locks | `mdsDealProcessingWorker` |
| Deal Enrichment Pipeline | Runs enrichment steps sequentially | `mdsDealEnrichmentPipeline` |
| Persistence Adapter | Writes computed deal deltas to PostgreSQL | `mdsDealPersistenceAdapter` |
| Notification Publisher | Publishes deal-change notifications to Redis queue | `mdsNotificationPublisher` |
| Inventory Update Publisher | Publishes inventory status updates to MBus | `mdsInventoryUpdatePublisher` |
| Marketing Deal Service Redis | Provides queues, locks, retry scheduling | `continuumMarketingDealServiceRedis` |
| Marketing Deal Service Database | Stores enriched deal data | `continuumMarketingDealDb` |
| Deal Catalog Service | Supplies catalog metadata and taxonomy | `continuumDealCatalogService` |
| Deal Management API | Supplies redemption location data | `continuumDealManagementApi` |
| M3 Places Service | Supplies place and Google Place metadata | `continuumM3PlacesService` |
| M3 Merchant Service | Supplies merchant operator location data | `continuumM3MerchantService` |
| Bhuvan Geo Service | Supplies geo/division enrichment | `continuumBhuvanService` |
| Pricing Service | Supplies pricing and margin data | `continuumPricingService` |
| SMA Metrics | Supplies performance metrics | `continuumSmaMetrics` |
| Salesforce | Supplies CRM merchant/deal attributes | `salesForce` |
| Message Bus | Receives published deal-change and inventory updates | `messageBus` |

## Steps

1. **Dequeue deal identifier**: Deal Processing Worker pulls the next deal identifier from the Redis processing queue.
   - From: `continuumMarketingDealServiceRedis`
   - To: `mdsDealProcessingWorker`
   - Protocol: RESP (Redis)

2. **Acquire distributed lock**: Worker acquires a per-deal lock in Redis to prevent concurrent processing of the same deal by another worker instance.
   - From: `mdsDealProcessingWorker`
   - To: `continuumMarketingDealServiceRedis`
   - Protocol: RESP (Redis SET NX with TTL)

3. **Trigger enrichment pipeline**: Worker delegates to the Deal Enrichment Pipeline component to execute the multi-step enrichment sequence.
   - From: `mdsDealProcessingWorker`
   - To: `mdsDealEnrichmentPipeline`
   - Protocol: in-process

4. **Fetch catalog and taxonomy data**: Pipeline calls Deal Catalog Service to retrieve catalog metadata, taxonomy classifications, and category hierarchy for the deal.
   - From: `mdsDealEnrichmentPipeline`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP + Events

5. **Backfill redemption locations**: Pipeline calls Deal Management API to retrieve redemption location associations for the deal.
   - From: `mdsDealEnrichmentPipeline`
   - To: `continuumDealManagementApi`
   - Protocol: HTTP

6. **Enrich place and merchant data**: Pipeline calls M3 Places Service for place/Google Place metadata and M3 Merchant Service for merchant operator locations.
   - From: `mdsDealEnrichmentPipeline`
   - To: `continuumM3PlacesService`, `continuumM3MerchantService`
   - Protocol: HTTP

7. **Enrich geo/division data**: Pipeline calls Bhuvan Geo Service to resolve geographic division assignments.
   - From: `mdsDealEnrichmentPipeline`
   - To: `continuumBhuvanService`
   - Protocol: HTTP

8. **Fetch pricing and margin data**: Pipeline calls Pricing Service to retrieve pricing rules and compute margin data.
   - From: `mdsDealEnrichmentPipeline`
   - To: `continuumPricingService`
   - Protocol: HTTP

9. **Fetch performance metrics**: Pipeline calls SMA Metrics to retrieve deal/merchant performance data (impressions, clicks, conversions, revenue).
   - From: `mdsDealEnrichmentPipeline`
   - To: `continuumSmaMetrics`
   - Protocol: HTTP

10. **Fetch CRM attributes**: Pipeline calls Salesforce to retrieve merchant/deal CRM attributes for enrichment.
    - From: `mdsDealEnrichmentPipeline`
    - To: `salesForce`
    - Protocol: HTTP

11. **Compute deal deltas**: Pipeline compares fetched data against the existing deal record and computes the set of fields that changed.
    - From: `mdsDealEnrichmentPipeline`
    - To: internal (in-process computation)
    - Protocol: in-process

12. **Persist deal updates**: Persistence Adapter writes computed deltas (taxonomy, division, margin, performance, location, CRM attributes) to PostgreSQL.
    - From: `mdsDealEnrichmentPipeline`
    - To: `mdsDealPersistenceAdapter` -> `continuumMarketingDealDb`
    - Protocol: JDBC (Sequelize)

13. **Publish deal-change notification**: Notification Publisher emits a deal-change notification to the Redis notification queue and/or message bus for downstream consumers.
    - From: `mdsDealEnrichmentPipeline`
    - To: `mdsNotificationPublisher` -> `continuumMarketingDealServiceRedis` / `messageBus`
    - Protocol: RESP / JMS/STOMP

14. **Publish inventory status update**: Inventory Update Publisher emits option-level inventory status updates to the message bus via the NBus Producer.
    - From: `mdsDealEnrichmentPipeline`
    - To: `mdsInventoryUpdatePublisher` -> `messageBus`
    - Protocol: JMS/STOMP (NBus)

15. **Release distributed lock**: Worker releases the per-deal lock in Redis after processing completes.
    - From: `mdsDealProcessingWorker`
    - To: `continuumMarketingDealServiceRedis`
    - Protocol: RESP (Redis DEL)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Lock acquisition failure | Worker skips deal; it will be processed by another worker instance or retried on next queue cycle | Deal processing deferred; no data loss |
| Deal Catalog Service unavailable | Enrichment aborted; deal re-enqueued with retry backoff | Deal retried after backoff; catalog data stale until successful enrichment |
| Place/Merchant/Bhuvan/Pricing service unavailable | Partial enrichment proceeds; missing fields skipped | Deal enriched with available data; missing fields retried on next cycle |
| Salesforce unavailable | CRM enrichment skipped | Deal enriched without CRM attributes; retried on next cycle |
| SMA Metrics unavailable | Performance enrichment skipped | Deal retains last-known performance data |
| PostgreSQL write failure | Enrichment fails; deal re-enqueued with retry backoff | Deal retried; if retries exhausted, moved to failed queue |
| Retry limit exceeded | Deal moved to Redis failed processing queue | Manual review required; alert fires on failed queue depth |

## Sequence Diagram

```
Redis -> mdsDealProcessingWorker: dequeue deal_id
mdsDealProcessingWorker -> Redis: SET NX lock:deal_id (acquire lock)
Redis --> mdsDealProcessingWorker: OK (lock acquired)
mdsDealProcessingWorker -> mdsDealEnrichmentPipeline: enrich(deal_id)
mdsDealEnrichmentPipeline -> continuumDealCatalogService: GET catalog + taxonomy
continuumDealCatalogService --> mdsDealEnrichmentPipeline: catalog data
mdsDealEnrichmentPipeline -> continuumDealManagementApi: GET redemption locations
continuumDealManagementApi --> mdsDealEnrichmentPipeline: location data
mdsDealEnrichmentPipeline -> continuumM3PlacesService: GET place metadata
continuumM3PlacesService --> mdsDealEnrichmentPipeline: place data
mdsDealEnrichmentPipeline -> continuumM3MerchantService: GET merchant locations
continuumM3MerchantService --> mdsDealEnrichmentPipeline: merchant data
mdsDealEnrichmentPipeline -> continuumBhuvanService: GET geo/division data
continuumBhuvanService --> mdsDealEnrichmentPipeline: geo data
mdsDealEnrichmentPipeline -> continuumPricingService: GET pricing/margin
continuumPricingService --> mdsDealEnrichmentPipeline: pricing data
mdsDealEnrichmentPipeline -> continuumSmaMetrics: GET performance metrics
continuumSmaMetrics --> mdsDealEnrichmentPipeline: metrics data
mdsDealEnrichmentPipeline -> salesForce: GET CRM attributes
salesForce --> mdsDealEnrichmentPipeline: CRM data
mdsDealEnrichmentPipeline -> mdsDealPersistenceAdapter: persist(deal_deltas)
mdsDealPersistenceAdapter -> continuumMarketingDealDb: INSERT/UPDATE deal data
continuumMarketingDealDb --> mdsDealPersistenceAdapter: OK
mdsDealEnrichmentPipeline -> mdsNotificationPublisher: publish(deal_change)
mdsNotificationPublisher -> messageBus: deal-change-notification
mdsDealEnrichmentPipeline -> mdsInventoryUpdatePublisher: publish(inventory_status)
mdsInventoryUpdatePublisher -> messageBus: inventory-option-status-update
mdsDealProcessingWorker -> Redis: DEL lock:deal_id (release lock)
```

## Related

- Architecture dynamic view: `dynamic-mds-deal-enrichment`
- Related flows: [Deal Event Consumption](deal-event-consumption.md), [Inventory Status Aggregation](inventory-status-aggregation.md), [CRM Salesforce Sync](crm-salesforce-sync.md)
