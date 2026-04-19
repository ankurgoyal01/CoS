---
service: "darwin-indexer"
title: "Deal Indexing Pipeline"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-indexing-pipeline"
flow_type: scheduled
trigger: "Quartz cron schedule (full rebuild or incremental delta)"
participants:
  - "continuumDealIndexerService"
  - "continuumDealCatalogService"
  - "continuumTaxonomyService"
  - "continuumGeoService"
  - "continuumMerchantApi"
  - "continuumInventoryService"
  - "continuumBadgesService"
  - "ugcReviewService"
  - "merchantPlaceReadService"
  - "continuumRedisCache"
  - "watsonItemFeatureBucket"
  - "elasticsearchCluster"
  - "holmesPlatform"
  - "kafkaCluster"
architecture_ref: "dynamic-deal-indexing-pipeline"
---

# Deal Indexing Pipeline

## Summary

The Deal Indexing Pipeline is darwin-indexer's core scheduled process. It runs on a Quartz cron schedule in either full-rebuild or incremental-delta mode. For each deal in scope, it fetches enrichment data from up to eight upstream services in parallel (using RxJava), assembles a fully-denormalized Elasticsearch document, bulk-writes the documents to the target index, and publishes an `ItemIntrinsicFeatureEvent` to Kafka for the Holmes ML ranking platform.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (cron expression configured in `config.yml`)
- **Frequency**: Periodic — full rebuild runs on a longer cadence (e.g., daily); incremental delta runs more frequently (e.g., every few minutes or hourly, depending on configuration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Indexer Service | Orchestrates the full pipeline; fetches, enriches, writes, and publishes | `continuumDealIndexerService` |
| Deal Catalog Service | Provides the source list of deal records to index | `continuumDealCatalogService` |
| Taxonomy Service | Provides category and taxonomy enrichment data | `continuumTaxonomyService` |
| Geo Service | Provides geo and location taxonomy data | `continuumGeoService` |
| Merchant API | Provides merchant profile and metadata | `continuumMerchantApi` |
| Inventory Service | Provides inventory availability data | `continuumInventoryService` |
| Badges Service | Provides deal badge assignments (e.g., "Top Pick") | `continuumBadgesService` |
| UGC Review Service | Provides user review scores and counts | `ugcReviewService` |
| Merchant Place Read Service | Provides merchant place and location records | `merchantPlaceReadService` |
| Redis Cache | Provides cached sponsored and feature flag data | `continuumRedisCache` |
| Watson Feature Bucket | Provides and receives item-level ML feature vectors | `watsonItemFeatureBucket` |
| Elasticsearch Cluster | Receives bulk-written enriched deal documents | `elasticsearchCluster` |
| Holmes Platform | Receives `ItemIntrinsicFeatureEvent` messages via Kafka | `holmesPlatform` |
| Kafka Cluster | Message broker for feature event delivery | `kafkaCluster` |

## Steps

1. **Schedule triggers job**: Quartz fires the configured deal indexing job (full rebuild or incremental delta).
   - From: Quartz scheduler (internal to `continuumDealIndexerService`)
   - To: `continuumDealIndexerService` indexing job handler
   - Protocol: internal / in-process

2. **Reads last offset (incremental only)**: For incremental runs, reads the last processed offset from PostgreSQL to determine which deals to fetch.
   - From: `continuumDealIndexerService`
   - To: PostgreSQL
   - Protocol: JDBC

3. **Fetches deal records**: Requests the batch of deal records in scope (full set or delta since last offset) from the Deal Catalog Service.
   - From: `continuumDealIndexerService`
   - To: `continuumDealCatalogService`
   - Protocol: REST (Retrofit2 HTTP client)

4. **Fetches enrichment data in parallel**: For each deal (or batch), issues concurrent REST requests to Taxonomy, Geo, Merchant API, Inventory, Badges, UGC Review, and Merchant Place services using RxJava parallel pipelines.
   - From: `continuumDealIndexerService`
   - To: `continuumTaxonomyService`, `continuumGeoService`, `continuumMerchantApi`, `continuumInventoryService`, `continuumBadgesService`, `ugcReviewService`, `merchantPlaceReadService`
   - Protocol: REST (Retrofit2 HTTP client)

5. **Reads Redis cache for sponsored/feature data**: Performs Redis lookups for sponsored campaign flags and feature data to supplement deal documents.
   - From: `continuumDealIndexerService`
   - To: `continuumRedisCache`
   - Protocol: Redis protocol

6. **Reads item feature vectors from S3**: Fetches pre-computed item feature data from Watson Feature Bucket for ML signal enrichment.
   - From: `continuumDealIndexerService`
   - To: `watsonItemFeatureBucket`
   - Protocol: S3 SDK

7. **Assembles enriched deal document**: Merges all fetched data into a fully-denormalized Elasticsearch document using Jackson serialization. Applies Joda-Money for pricing field normalization.
   - From: `continuumDealIndexerService` (internal merge step)
   - To: `continuumDealIndexerService` (document buffer)
   - Protocol: internal / in-process

8. **Bulk-writes documents to Elasticsearch**: Sends accumulated enriched documents to Elasticsearch via the Bulk API in configurable batch sizes.
   - From: `continuumDealIndexerService`
   - To: `elasticsearchCluster`
   - Protocol: Elasticsearch HTTP / transport

9. **Publishes ItemIntrinsicFeatureEvent**: For each processed deal, publishes an `ItemIntrinsicFeatureEvent` to the Holmes platform Kafka topic with the item's intrinsic feature vector.
   - From: `continuumDealIndexerService`
   - To: `kafkaCluster` / `holmesPlatform`
   - Protocol: Kafka producer

10. **Writes computed features back to S3 (if applicable)**: Persists any newly computed feature data back to Watson Feature Bucket for future use.
    - From: `continuumDealIndexerService`
    - To: `watsonItemFeatureBucket`
    - Protocol: S3 SDK

11. **Updates run state and offset in PostgreSQL**: Records the completed run metadata (status, document count, duration) and updates the incremental offset for the next run.
    - From: `continuumDealIndexerService`
    - To: PostgreSQL
    - Protocol: JDBC

12. **Triggers alias switchover (full rebuild only)**: On completion of a full index rebuild, invokes the alias switchover process to make the new index live.
    - From: `continuumDealIndexerService`
    - To: `elasticsearchCluster`
    - Protocol: Elasticsearch HTTP
    - See: [Index Alias Switchover](index-alias-switchover.md)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Upstream REST service unavailable | Exception thrown; RxJava pipeline propagates error; job marks run as failed | Indexing run aborted; previous index remains live; run state recorded as failed in PostgreSQL; next scheduled run will retry |
| Elasticsearch bulk write partial failure | Bulk API response inspected for per-document errors; failed documents logged | Successfully written documents indexed; failed documents skipped; operator alerted via metrics |
| Kafka publish failure | Exception logged; feature event not delivered | Deal indexed to Elasticsearch; Holmes platform misses feature update for affected items; next run may re-publish |
| Redis unavailable | Exception propagated; deal enrichment continues without cached data or job fails | Depends on implementation: either sponsored data omitted or run aborted |
| PostgreSQL unavailable | Cannot read/write run state or offsets | Incremental run cannot determine correct offset; may fall back to full rebuild or abort |
| S3 unavailable | Feature data not available | Deal indexed without ML feature enrichment; feature event may be published with empty/default features |

## Sequence Diagram

```
Quartz -> DealIndexerService: Fire scheduled job
DealIndexerService -> PostgreSQL: Read last offset (incremental)
DealIndexerService -> DealCatalogService: GET /deals?since={offset}
DealCatalogService --> DealIndexerService: Deal records
DealIndexerService -> TaxonomyService: GET /taxonomy/{ids} (parallel)
DealIndexerService -> GeoService: GET /geo/{ids} (parallel)
DealIndexerService -> MerchantApi: GET /merchants/{ids} (parallel)
DealIndexerService -> InventoryService: GET /inventory/{ids} (parallel)
DealIndexerService -> BadgesService: GET /badges/{ids} (parallel)
DealIndexerService -> UGCReviewService: GET /reviews/{ids} (parallel)
DealIndexerService -> MerchantPlaceReadService: GET /places/{ids} (parallel)
DealIndexerService -> RedisCache: GET feature:{dealId} / sponsored:{dealId}
DealIndexerService -> WatsonFeatureBucket: S3 GetObject item-features/{dealId}
DealIndexerService -> DealIndexerService: Merge and assemble document
DealIndexerService -> ElasticsearchCluster: POST /_bulk (enriched documents)
ElasticsearchCluster --> DealIndexerService: Bulk response (success / per-doc errors)
DealIndexerService -> KafkaCluster: Produce ItemIntrinsicFeatureEvent
DealIndexerService -> WatsonFeatureBucket: S3 PutObject (computed features)
DealIndexerService -> PostgreSQL: Update run state and offset
DealIndexerService -> ElasticsearchCluster: POST /_aliases (switchover, full rebuild only)
```

## Related

- Architecture dynamic view: `dynamic-deal-indexing-pipeline`
- Related flows: [Hotel Offer Indexing](hotel-offer-indexing.md), [Index Alias Switchover](index-alias-switchover.md), [Logging and Validation](logging-and-validation.md), [Metrics Export](metrics-export.md)
