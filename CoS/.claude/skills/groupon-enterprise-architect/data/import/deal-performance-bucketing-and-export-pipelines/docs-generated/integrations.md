---
service: "deal-performance-bucketing-and-export-pipelines"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 3
---

# Integrations

## Overview

The service integrates with four external infrastructure systems (GCS, HDFS/Janus, PostgreSQL, and Wavefront/Telegraf) and three internal Groupon platform components (Airflow orchestrator, Janus experiment store, and the deal-performance-api-v2 API layer). All integrations are batch-oriented — no synchronous HTTP calls are made at runtime.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCS (Google Cloud Storage) | GCS Hadoop connector | Raw event input and bucketed Avro output storage | yes | `hdfsCluster` |
| Janus / HDFS | HDFS API | A/B experiment instance data for event decoration | no | `hdfsCluster` |
| GDS PostgreSQL | JDBC (port 5432) | Stores aggregated performance data for API access | yes | `continuumDealPerformancePostgres` |
| Wavefront / Telegraf | HTTP | Pipeline execution metrics publishing | no | `influxDb` |

### GCS (Google Cloud Storage)

- **Protocol**: GCS via Hadoop FileSystem API (`GoogleHadoopFileSystem`)
- **Base URL / SDK**: `gs://grpn-dnd-prod-analytics-grp-mars-mds` (production); `gs://grpn-dnd-stable-analytics-grp-mars-mds` (staging) — configured in `userDealBucketingPipelineConfig.gcsUrl`
- **Auth**: GCP service account (resolved via Spark/EMR instance profile)
- **Purpose**: Primary data lake. Reads raw `InstanceStoreAttributedDealImpression` events; writes bucketed `AvroDealPerformance` Avro files partitioned by event source, date, hour, and event type.
- **Failure mode**: Pipeline fails and Airflow task is marked failed; Airflow handles retry. No data is partially committed.
- **Circuit breaker**: No — pipeline uses Beam retry semantics on file reads.

### Janus / HDFS (A/B Experiment Data)

- **Protocol**: HDFS API via `hdfs://gdoop-namenode`
- **Base URL / SDK**: `hdfs://gdoop-namenode/user/grp_gdoop_platform-data-eng/janus` — configured in `eventDecorationPipelineConfig.inputPath`
- **Auth**: Kerberos / HDFS principal (EMR cluster credentials)
- **Purpose**: Provides A/B experiment instance records (experiment ID, bcookie) for joining with deal events during the bucketing pipeline. The experiment decoration sub-pipeline is independently enable/disable-able via `eventDecorationPipelineConfig.enabled`.
- **Failure mode**: If experiment data is missing for a date-hour, the pipeline logs a warning and continues with empty experiment data (events are bucketed without experiment attribution).
- **Circuit breaker**: No.

### GDS PostgreSQL

- **Protocol**: JDBC (PostgreSQL wire protocol, port 5432)
- **Base URL / SDK**: `deal-performance-service-v2-rw-na-production-db.gds.prod.gcp.groupondev.com` (production NA) — configured in `dealPerformanceExportPipelineConfig.dbConfig.host`
- **Auth**: Username/password from config file (`deal_perf_v2_prod_app`). Password may be overridden by `--dbPassword` pipeline argument.
- **Purpose**: Stores hourly and daily aggregated performance counts. Supports deduplication via unique constraint + insert-or-ignore stored procedure pattern.
- **Failure mode**: JDBC write failures cause the Beam export pipeline to fail; Airflow retry is triggered.
- **Circuit breaker**: No explicit circuit breaker. Connection pool size is configured (`transactionPoolSize: 2`).

### Wavefront / Telegraf (Metrics)

- **Protocol**: HTTP to Telegraf endpoint
- **Base URL / SDK**: `http://telegraf.default.prod.us-central1.gcp.groupondev.com` (production) — configured in `commonConfig.wavefront.endpoint`
- **Purpose**: Receives pipeline metrics (counter, timer, gauge) for Wavefront dashboards and alerting.
- **Failure mode**: Non-blocking; metric publication failures are logged but do not fail the pipeline.
- **Circuit breaker**: No.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Airflow (relevance-airflow) | DAG task invocation | Schedules and orchestrates the three pipeline tasks (DpsUserDealBucketingTask, DpsDbExportTask, DpsDbCleanerTask) | — |
| Janus (platform-data-eng) | HDFS file read | Provides experiment participation data for event decoration | `hdfsCluster` |
| deal-performance-api-v2 | Reads from PostgreSQL | Reads the exported aggregates to serve the REST API (separate repo / subservice) | — |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Relevance Ranking Spark jobs | GCS file read | Read bucketed `AvroDealPerformance` files for scoring and ranking pipeline features |
| deal-performance-api-v2 | PostgreSQL reads | Exposes deal performance metrics via REST API to MDS and merchant dashboard consumers |

> Upstream consumers of the GCS output are tracked in the central architecture model and the Airflow DAG configuration.

## Dependency Health

- GCS and HDFS failures are surfaced as Airflow task failures with Slack/PagerDuty alerts via `darwin-offline` channel.
- PostgreSQL health is monitored through Wavefront dashboards; no application-level health check endpoint is exposed.
- The `[DPS V2] Job Not Running` Wavefront alert fires if no pipeline execution has been detected for 2 hours.
