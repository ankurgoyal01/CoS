---
service: "badges-trending-calculator"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

Badges Trending Calculator is a pure event consumer. It reads `DealPurchase` events from the Janus Kafka topic (`janus-tier1` in production, `janus-cloud-tier1` in staging) via Spark Structured Streaming with Kafka SSL authentication. It does not publish events to any topic; results are materialized directly into Redis.

## Published Events

> This service does not publish any async events to Kafka or other messaging systems. Output is written directly to `continuumBadgesRedisStore` (Redis).

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `janus-tier1` (prod) / `janus-cloud-tier1` (staging) | `DealPurchase` | `BadgeCalculatorProcessor` | Aggregates purchase counts per deal UUID; writes Trending and Top Seller rankings to Redis |

### DealPurchase Detail

- **Topic**: `janus-tier1` (NA production), `janus-cloud-tier1` (staging), `janus-tier1` (EMEA production)
- **Handler**: `BadgeCalculatorProcessor` receives a Spark DataFrame of DealPurchase rows per micro-batch. Each row carries `dealUUID`, `country`, `dealPermalink`, `quantity`, and `eventTime`. The processor filters invalid rows, deduplicates by `dealUUID` (sum of quantity), enriches with division/channel via Watson, then partitions by `deal_info.divison` and `deal_info.channel` and calls `ProcessorTask.calculatorTask` per partition.
- **Key payload fields**: `dealUUID`, `country`, `dealPermalink`, `quantity`, `eventTime`, `consumerId`
- **Idempotency**: Not guaranteed. Kafka offset is committed after each micro-batch. Re-processing a batch increments Redis hash counts again.
- **Error handling**: Invalid rows (empty dealUUID, country, permalink or failed country/deal validation) are filtered out before processing. Watson HTTP errors are caught and logged; the row is dropped. Redis connection errors (`JedisConnectionException`) are caught per base-key iteration with 5-attempt retry (50ms interval).
- **Processing order**: Unordered within micro-batch; partitioned by division and channel.
- **Batch interval**: 600 seconds (production), configurable via `--batch_interval` argument.
- **Consumer group ID**: `mds_janus_msk_dev` (configured via `--groupId` argument).
- **Offset reset**: `latest` (configured via `--offsetReset` argument).

## Dead Letter Queues

> No evidence found in codebase. Failed events are dropped after logging; there is no DLQ configured.
