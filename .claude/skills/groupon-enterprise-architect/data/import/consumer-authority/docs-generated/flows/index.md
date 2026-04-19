---
service: "consumer-authority"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Consumer Authority.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Daily Attribute Pipeline](daily-attribute-pipeline.md) | batch / scheduled | Airflow daily schedule | End-to-end run: Airflow triggers Job Orchestrator, Attribute Pipeline discovers scripts, Spark executes transformations, writes to Hive, publishes to Kafka/AMS, alerts on completion |
| [Backfill Pipeline](backfill-pipeline.md) | batch | Manual or Airflow trigger | Recomputes historical consumer attributes for one or more past run dates, overwrites output partitions in the Consumer Authority Warehouse |
| [Attribute Publication](attribute-publication.md) | batch | Triggered after Spark transformations complete | Reads derived tables, selects publishable attributes, posts events to Holmes/Kafka and metadata to the Audience Management Service |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

All three flows span multiple systems in the Continuum architecture:

- Airflow triggers `continuumConsumerAuthorityService` via Cerebro Job Submitter
- `continuumConsumerAuthorityService` reads from `hiveWarehouse` and `hdfsStorage`
- Output is written to `continuumConsumerAuthorityWarehouse`
- Derived signals are published to `messageBus` (Kafka)
- Metadata updates are pushed to `continuumAudienceManagementService`

Architecture dynamic view: `dynamic-daily-attribute-pipeline`
