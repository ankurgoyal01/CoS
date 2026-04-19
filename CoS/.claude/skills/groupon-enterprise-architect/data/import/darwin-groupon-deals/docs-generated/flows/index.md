---
service: "darwin-groupon-deals"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for the Darwin Aggregator Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [REST Deal Search](rest-deal-search.md) | synchronous | Inbound HTTP GET to `/v2/deals/search` or `/cards/v1/search` | Consumer submits a deal search; service checks cache, fans out to upstream services, ranks results with ML model, returns ranked deal list |
| [Async Batch Aggregation](async-batch-aggregation.md) | asynchronous | Aggregation request event consumed from Kafka | Service reads a batch aggregation request from Kafka, executes full fan-out and ranking pipeline, publishes aggregated response back to Kafka |
| [Deal Ranking and Personalization](deal-ranking-personalization.md) | synchronous | Invoked internally by aggregationEngine during any aggregation request | Loads ML model artifacts from Watson Object Storage, scores deal candidates, applies personalization signals from user identity and audience attributes, returns ordered list |
| [Cache Warming](cache-warming.md) | event-driven | Post-aggregation write-back after each successful aggregation cycle | After a successful aggregation response, cacheLayer serializes and writes the result to Redis to warm the cache for subsequent identical requests |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Event-driven (internal) | 1 |

## Cross-Service Flows

- The REST Deal Search and Async Batch Aggregation flows both span `continuumDarwinAggregatorService`, `continuumDealCatalogService`, `continuumBadgesService`, `continuumUserIdentitiesService`, `continuumGeoPlacesService`, and `continuumGeoDetailsService`. These cross-service interactions are referenced in the central architecture model under `continuumSystem`.
- Architecture dynamic views: no dynamic views are currently defined in the DSL (`dynamics.dsl` is empty). See component view `darwinAggregatorServiceComponents` for the static component layout.
