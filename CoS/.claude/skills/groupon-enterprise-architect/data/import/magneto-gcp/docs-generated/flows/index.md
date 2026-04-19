---
service: "magneto-gcp"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for magneto-gcp.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [DAG Generation](dag-generation.md) | batch | Deploy / Docker container startup | Generates Airflow DAG Python files from YAML table config and writes them to the Composer DAGs GCS bucket |
| [Salesforce Incremental Ingestion (zombie_runner mode)](salesforce-incremental-ingestion.md) | scheduled | Airflow cron schedule per table | Full incremental ETL: provisions Dataproc cluster, extracts from Salesforce, stages to GCS, loads to Hive, updates watermark |
| [Salesforce Simple Ingestion (simple_salesforce mode)](salesforce-simple-ingestion.md) | scheduled | Airflow cron schedule per table | Variant ingestion using Python simple_salesforce library for extract with in-process GCS write, then Dataproc Hive load |
| [Salesforce Data Validation (Audit)](salesforce-validation-audit.md) | scheduled | Airflow cron schedule per table (audit_schedule) | Compares Salesforce row counts against Hive table counts for each data interval; alerts on mismatch |
| [Ingestion Metrics Reporting](ingestion-metrics-reporting.md) | scheduled | Every 30 minutes (Airflow DAG `magneto_metric_gcp`) | Queries table_limits watermark state and pushes lag metrics to Telegraf/InfluxDB |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

The Salesforce Incremental Ingestion flow is the primary cross-service flow documented in the architecture model:

- Architecture dynamic view: `dynamic-magneto-salesforce-ingestion-flow`
- Participants: `continuumMagnetoDagGenerator`, `continuumMagnetoOrchestrator`, `continuumMagnetoConfigStorage`, `salesForce`, `cloudPlatform`, `metricsStack`
- Reference: [Salesforce Incremental Ingestion](salesforce-incremental-ingestion.md)
