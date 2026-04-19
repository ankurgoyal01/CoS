---
service: "clam-load-generator"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for CLAM Load Generator.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Load Generation Orchestration](load-generation-orchestration.md) | batch | `ApplicationReadyEvent` at JVM startup | Core orchestration loop: resolves strategy, spawns thread pool, applies rate limiter, executes operation batches, and prints summary |
| [Kafka Load Generation](kafka-load-generation.md) | batch | `test-target=kafka` profile + startup | Discovers Kafka partitions, generates JSON metric line payloads per partition, and publishes to the `histograms_v2` topic |
| [Telegraf Load Generation](telegraf-load-generation.md) | batch | `test-target=telegraf` profile + startup | Generates InfluxDB line-protocol `Point` objects per thread and writes them directly to a Telegraf HTTP listener |
| [SMA Load Generation](sma-load-generation.md) | batch | `test-target=sma` profile + startup | Builds SMA `ImmutableMeasurement` batches using jtier metrics and submits them through the `BufferingInfluxWriter` to a Telegraf endpoint |
| [Post-Load Verification](post-load-verification.md) | batch | Completion of `LoadGenerator.start()` | Writes known test metric values to Telegraf or the gateway, waits for CLAM aggregation, and queries Wavefront to assert expected aggregate values |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 (Kafka publish) |
| Batch / Scheduled | 4 |

## Cross-Service Flows

The load generation runtime flow is documented in the architecture dynamic view:

- `dynamic-clam-load-generation-flow` — end-to-end flow from `LoadGenerationOrchestrator` through strategy selection to backend writes and Wavefront verification

This flow spans the following external systems:
- `continuumMetricsClamLoadGenerator` → Apache Kafka (`histograms_v2` topic)
- `continuumMetricsClamLoadGenerator` → Telegraf HTTP listener
- `continuumMetricsClamLoadGenerator` → Wavefront Query API
