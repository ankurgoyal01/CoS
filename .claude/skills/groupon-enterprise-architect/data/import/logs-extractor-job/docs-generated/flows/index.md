---
service: "logs-extractor-job"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Log Extractor Job.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Hourly Log Extraction and Load](hourly-log-extraction.md) | scheduled | Kubernetes CronJob at `1 * * * *` | End-to-end flow from schedule trigger through Elasticsearch extraction to BigQuery and MySQL upload |
| [BigQuery Table Initialization](bigquery-table-init.md) | batch | Start of each job run when BigQuery is enabled | Ensures BigQuery dataset and all 6 tables exist before any upload; creates if missing with DAY partitioning |
| [Log Transformation and BigQuery Upload](log-transform-bigquery-upload.md) | batch | After extraction, when BigQuery is enabled | Transforms each log type and uploads in batches of 500 rows to the corresponding BigQuery table |
| [Combined Logs Denormalization](combined-logs-denormalization.md) | batch | After per-type uploads, when PWA logs are present | Joins PWA, proxy, Lazlo, and orders logs by requestId to produce denormalized combined_logs records |
| [BCookie Session Summary Generation](bcookie-summary-generation.md) | batch | After PWA log extraction, when PWA logs are present | Aggregates per-bCookie event counts, session counts, and purchase/error flags from PWA logs |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

The `dynamic-hourly-log-extraction` dynamic view in the Structurizr architecture model documents the top-level flow across `continuumLogExtractorJob`, `continuumLogExtractorElasticsearch`, `continuumLogExtractorBigQuery`, and `continuumLogExtractorMySQL`. See [Architecture Context](../architecture-context.md) for container-level relationships.
