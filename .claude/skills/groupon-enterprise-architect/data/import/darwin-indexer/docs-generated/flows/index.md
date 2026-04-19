---
service: "darwin-indexer"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for darwin-indexer.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Indexing Pipeline](deal-indexing-pipeline.md) | scheduled | Quartz cron schedule (full and incremental) | Aggregates deal data from multiple upstream services, enriches documents, and bulk-writes them to Elasticsearch |
| [Hotel Offer Indexing](hotel-offer-indexing.md) | scheduled | Quartz cron schedule | Fetches hotel offer and taxonomy data, builds enriched hotel offer documents, and bulk-writes them to Elasticsearch |
| [Index Alias Switchover](index-alias-switchover.md) | batch | Completion of a full index rebuild | Atomically switches the Elasticsearch read alias from the old index to the newly built index with zero downtime |
| [Metrics Export](metrics-export.md) | scheduled | Continuous / periodic Dropwizard Metrics reporter interval | Exports operational metrics from Dropwizard Metrics to the monitoring backend |
| [Logging and Validation](logging-and-validation.md) | event-driven | Each indexing job run and document write | Validates document structure, logs indexing progress and errors, and records run outcomes to PostgreSQL |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

The **Deal Indexing Pipeline** spans the largest number of services: `continuumDealIndexerService` coordinates calls to `continuumDealCatalogService`, `continuumTaxonomyService`, `continuumGeoService`, `continuumMerchantApi`, `continuumInventoryService`, `continuumBadgesService`, `ugcReviewService`, and `merchantPlaceReadService`, then writes to `elasticsearchCluster` and publishes to `holmesPlatform` via `kafkaCluster`. This is the primary cross-service flow in the darwin-indexer system.

The **Hotel Offer Indexing** flow spans `continuumHotelOfferIndexerService`, `hotelOfferCatalogService`, `continuumTaxonomyService`, and `elasticsearchCluster`.

Both indexing flows terminate with the **Index Alias Switchover** flow on full rebuilds.
