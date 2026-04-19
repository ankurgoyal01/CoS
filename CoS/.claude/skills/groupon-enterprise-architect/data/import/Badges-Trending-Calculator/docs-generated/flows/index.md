---
service: "badges-trending-calculator"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Badges Trending Calculator.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Purchase Badge Computation](deal-purchase-badge-computation.md) | event-driven | `DealPurchase` event on `janus-tier1` Kafka topic | Core flow: consumes purchase events, enriches deal metadata, and computes Trending and Top Seller rankings written to Redis |
| [Geo Division Refresh](geo-division-refresh.md) | scheduled | Hourly scheduler (every 60 minutes) | Fetches current supported geographic divisions from Bhuvan and caches them in Redis for use by the processor filter |
| [Daily Job Restart via Airflow](daily-job-restart.md) | scheduled | Airflow DAG cron `22 3 * * *` (03:22 UTC) | Tears down and recreates the Dataproc cluster, then submits the Spark job to restart the long-running streaming application |
| [Trending and Top Seller Ranking Computation](trending-ranking-computation.md) | event-driven | Per Spark partition during each micro-batch | Reads 7-day rolling Redis hashes, applies daily decay, computes Top-500 ranked lists, and writes final badge state to Redis |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The `dynamic-deal-purchase-badge-computation` Structurizr dynamic view captures the end-to-end cross-service flow spanning `janusTier1Topic`, `continuumBadgesTrendingCalculator`, `watsonKv`, `continuumBhuvanService`, and `continuumBadgesRedisStore`. See [Architecture Context](../architecture-context.md) for container relationship details.
