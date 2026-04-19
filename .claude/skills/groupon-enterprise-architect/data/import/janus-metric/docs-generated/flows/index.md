---
service: "janus-metric"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Janus Business Metric.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Janus Volume and Quality Cube Aggregation](janus-volume-quality-aggregation.md) | batch | Airflow `@hourly` (`janus-metric` DAG) | Reads Janus validated-event Parquet files from GCS, computes volume, quality, and catfood quality cubes via Spark SQL, and persists them to the Janus Metadata Service API |
| [Janus Raw Event Audit Aggregation](janus-raw-event-audit.md) | batch | Airflow `@hourly` (`janus-raw-metric` DAG) | Counts raw events per source topic and event type from 11 Kafka-sourced GCS files (NA and INTL regions), and persists audit cubes to the Janus Metadata Service |
| [Juno Hourly Volume Cube Aggregation](juno-volume-aggregation.md) | batch | Airflow `@daily` (`juno-metric` DAG) | Reads Juno hourly Parquet files from GCS, computes Juno volume cubes with country filtering, and persists them to the Janus Metadata Service |
| [Attribute Cardinality Computation](attribute-cardinality.md) | batch | Airflow `@weekly` (`janus-cardinality-topN` DAG) | Reads Jupiter attribute Parquet data, computes approximate distinct cardinality and top-5 values per attribute, and persists results to the Janus Metadata Service |
| [Ultron Watermark Delta Management](ultron-watermark-delta.md) | batch | Invoked at the start of each metric flow | Queries Ultron API for the current high-watermark, lists new GCS files since last run, and updates watermark state after processing |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

All flows in this service are batch-scheduled and cross into two external services:

- **Janus Metadata Service** (`janus-web-cloud`) — receives all metric cube POSTs from every flow. See [Integrations](../integrations.md).
- **Ultron API** — provides watermark state for every flow. See [Ultron Watermark Delta Management](ultron-watermark-delta.md).
