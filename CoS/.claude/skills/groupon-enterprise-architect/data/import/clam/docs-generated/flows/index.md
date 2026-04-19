---
service: "clam"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for CLAM (Cluster-Level Aggregation of Metrics).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Histogram Aggregation](histogram-aggregation.md) | event-driven | Kafka message on `metrics_histograms_v2` | Core processing flow: decode TDigest histograms, merge cluster-level state, emit aggregates to Kafka |
| [Job Startup and Initialisation](job-startup.md) | scheduled | gdoop-cron YARN restarter (every 1 min if not running) | Bootstraps Spark session, loads config, wires listeners, connects InfluxDB, starts streaming query |
| [Bad Data Handling](bad-data-handling.md) | event-driven | Malformed or incomplete histogram event received | Validates incoming histogram records; filters bad data and increments bad-data counter metric |
| [Operational Metrics Reporting](operational-metrics.md) | scheduled | Spark job/query progress events (every ~1 min micro-batch) | Publishes processing-time, input-count, speculative-task-count, and heartbeat metrics to Metrics Gateway |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The histogram aggregation flow spans three systems:
1. **Upstream producers** (metrics-gateway / Telegraf) — publish histogram events to `metrics_histograms_v2`
2. **CLAM** (`continuumClamSparkStreamingJob`) — aggregates and re-publishes
3. **Downstream consumers** (metric storage / Wavefront forwarder) — consume from `metrics_aggregates`

The architecture dynamic view for this cross-service flow is defined in `structurizr/import/clam/architecture/views/dynamics/clamHistogramAggregationFlow.dsl` but is currently disabled pending federation of external Kafka topic identifiers into the central workspace.
