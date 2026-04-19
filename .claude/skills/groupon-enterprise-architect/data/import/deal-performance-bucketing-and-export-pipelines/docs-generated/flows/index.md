---
service: "deal-performance-bucketing-and-export-pipelines"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for the Deal Performance Data Pipelines.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Event Bucketing](deal-event-bucketing.md) | batch | Airflow DAG task (DpsUserDealBucketingTask) | Reads raw deal events from GCS, decorates with geo and experiment data, buckets by user dimensions, writes Avro output to GCS |
| [Experiment Event Decoration](experiment-event-decoration.md) | batch | Sub-step within DpsUserDealBucketingTask | Reads A/B experiment instance records from Janus HDFS and joins to deal events by bcookie |
| [Deal Performance DB Export](deal-performance-db-export.md) | batch | Airflow DAG task (DpsDbExportTask) | Reads bucketed GCS output, aggregates by time granularity (hourly/daily), writes to PostgreSQL |
| [Deal Performance DB Cleanup](deal-performance-db-cleanup.md) | scheduled | Airflow DAG task (DpsDbCleanerTask) | Deletes stale rows from deal performance PostgreSQL tables based on a retention date |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

- The bucketing pipeline reads raw deal event data produced by upstream instance store services written to GCS — coordination is by shared GCS path convention, not a direct service call.
- The DB export pipeline output in PostgreSQL is consumed by the `deal-performance-api-v2` subservice (separate repo) to serve REST API queries.
- Downstream Relevance Ranking Spark jobs read GCS bucketed output produced by the bucketing pipeline.
- All pipeline scheduling and inter-step ordering is managed by Apache Airflow DAGs hosted on `relevance-airflow`.
