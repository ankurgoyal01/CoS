---
service: "megatron-gcp"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Megatron GCP.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [DAG Generation](dag-generation.md) | batch | Jenkins CI/CD pipeline build step | Reads YAML factory configs and writes Airflow DAG Python files for all MySQL and Postgres services |
| [MySQL Ingestion Pipeline](mysql-ingestion-pipeline.md) | scheduled | Airflow cron schedule per service/partition/mode | Runs sqoop, load, merge, or full_load for MySQL source tables onto Dataproc, writing results to Teradata |
| [Postgres Ingestion Pipeline](postgres-ingestion-pipeline.md) | scheduled | Airflow cron schedule per service/partition/mode | Same as MySQL pipeline but for PostgreSQL sources; adds BigQuery service account key distribution |
| [Audit and Validation](audit-and-validation.md) | scheduled | Airflow cron schedule per service | Runs Hive, MySQL/Postgres source, BigQuery, and Teradata count-checks and reconciliation after ingestion cycles |
| [BigQuery Data Quality Comparison](bigquery-data-quality.md) | batch | Manual / Airflow operator call | Compares datastream tables against backfill tables in BigQuery for schema compatibility, record counts, primary-key overlap, sample integrity, and data freshness |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

The ingestion pipeline flows span `continuumMegatronGcp` (DAG orchestration), GCP Dataproc (compute), GCS (staging), GCP Secret Manager (credentials), the source MySQL/Postgres databases (on-prem), Teradata (destination), and BigQuery (CDC destination and audit target). The central architecture dynamic view for the ingestion flow was deferred — see `architecture/views/dynamics/megatronIngestionFlow.dsl` for the planned representation.
