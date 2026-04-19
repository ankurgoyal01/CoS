---
service: "badges-trending-calculator"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumBadgesTrendingCalculator, continuumBadgesRedisStore]
---

# Architecture Context

## System Context

Badges Trending Calculator is a batch-streaming container within the `continuumSystem` (Continuum Platform). It sits downstream of the Janus event bus and upstream of `badges-service`. Purchase events flow in from the `janus-tier1` Kafka topic, are enriched by `watsonKv` and `continuumBhuvanService`, and the resulting badge rankings are materialized in `continuumBadgesRedisStore` — the same Redis store read by `badges-service` to serve deal badges to Groupon frontends.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Badges Trending Calculator | `continuumBadgesTrendingCalculator` | Streaming / Batch | Scala, Apache Spark Streaming (CDE Job Framework) | 2.4.8 | Spark streaming job that computes Trending and Top Seller badges from Janus deal purchase events. |
| Badges Redis Store | `continuumBadgesRedisStore` | Database / Cache | Redis | — | Redis keyspace for intermediate daily deal-count hashes, final weekly badge rankings, and cached supported divisions. |

## Components by Container

### Badges Trending Calculator (`continuumBadgesTrendingCalculator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Janus DealPurchase Ingestion (`janusDealPurchaseIngestion`) | Entry point; extends `JanusStreamingCSparkJob` to consume `DealPurchase` events from the Janus Kafka topic and dispatch micro-batch DataFrames. | `BadgeCalculator` (Scala object) |
| Badge Calculator Processor (`badgeCalculatorProcessor`) | Filters, deduplicates, and aggregates purchase events; enriches with division/channel via Watson; routes per-partition rows to the Trending Computation Engine. | `BadgeCalculatorProcessor` (Scala class) |
| Watson Intrinsic Adapter (`watsonIntrinsicAdapter`) | HTTPS client that looks up item-intrinsic metadata (channel, division, merchantServiceCategory) for a given deal UUID. | `WatsonServiceClient` |
| Trending Computation Engine (`trendingComputationEngine`) | Computes 7-day rolling Trending (decayed) and Top Seller (raw) Top-500 rankings per partition; reads/writes Redis hashes. | `ProcessorTask` |
| Geo Division Scheduler (`geoDivisionScheduler`) | Hourly scheduled task that refreshes the set of supported geographic divisions from Bhuvan and caches them in Redis. | `GeoServiceTask` |
| Geo Service Adapter (`geoServiceAdapter`) | HTTPS client that fetches division permalinks by country from the Bhuvan geo-places service. | `GeoServiceClient` |
| Redis Persistence Adapter (`redisPersistenceAdapter`) | Unified `DBHandle` abstraction backed by Jedis (standalone) or Lettuce (cluster) depending on `redisConfig.mode`. | `DBHandleFactory`, `JedisClient`, `LettuceClient` |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `janusTier1Topic` | `continuumBadgesTrendingCalculator` | Streams DealPurchase events | Kafka (SSL) |
| `continuumBadgesTrendingCalculator` | `watsonKv` | Reads item intrinsic metadata over HTTPS | HTTPS |
| `continuumBadgesTrendingCalculator` | `continuumBhuvanService` | Reads geoplaces divisions over HTTPS | HTTPS |
| `continuumBadgesTrendingCalculator` | `continuumBadgesRedisStore` | Reads/writes badge aggregates and division cache | Redis |
| `janusDealPurchaseIngestion` | `badgeCalculatorProcessor` | Dispatches Janus DealPurchase micro-batches | in-process |
| `badgeCalculatorProcessor` | `watsonIntrinsicAdapter` | Fetches deal intrinsic metadata for division/channel enrichment | in-process / HTTPS |
| `badgeCalculatorProcessor` | `trendingComputationEngine` | Invokes per-partition ranking computation | in-process |
| `trendingComputationEngine` | `redisPersistenceAdapter` | Reads historical hashes and writes computed badge rankings | in-process / Redis |
| `geoDivisionScheduler` | `geoServiceAdapter` | Fetches supported divisions for configured countries | in-process / HTTPS |
| `geoDivisionScheduler` | `redisPersistenceAdapter` | Caches supported divisions for filter checks | in-process / Redis |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumBadgesTrendingCalculator`
- Dynamic view: `dynamic-deal-purchase-badge-computation`
