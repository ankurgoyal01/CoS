---
service: "cas-data-pipeline-dags"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for CAS Data Pipeline DAGs.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [NA Email Data Pipeline](na-email-data-pipeline.md) | batch | Manual / external trigger | Processes NA email engagement data (BG-CG mapping, sends, opens, clicks, unsubscribes, orders) on Dataproc to populate Hive feature tables |
| [NA Email ML Feature Pipeline](na-email-ml-feature-pipeline.md) | batch | Manual / external trigger | Computes ML features for NA email arbitration (user, campaign, segment, funnel features) on an ephemeral Dataproc cluster |
| [NA Email Arbitration Ranking](na-email-arbitration-ranking.md) | batch | Manual / external trigger | Runs the `ModelRanking` Spark job on Dataproc to produce final email arbitration ranking scores |
| [NA Mobile Data Pipeline](na-mobile-data-pipeline.md) | batch | Manual / external trigger | Processes NA mobile engagement data (sends, clicks, orders, aggregation) on Dataproc to populate Hive feature tables |
| [Arbitration Reporting Pipeline](arbitration-reporting-pipeline.md) | batch | Manual / external trigger | Runs `MainLogToCerebro` data transformation Spark job to generate NA and EMEA arbitration reporting output |
| [Janus-YATI Kafka Ingestion](janus-yati-kafka-ingestion.md) | event-driven | Manual trigger with optional JAR override | Runs Spark Structured Streaming job on Dataproc to consume `arbitration_log` Kafka topic and write output to GCS |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

All batch flows interact with:
- `continuumCasDataPipelineDags` — DAG orchestrator (creates Dataproc cluster, submits jobs, deletes cluster)
- `continuumCasSparkBatchJobs` — Spark assembly JAR executing inside Dataproc
- `hiveWarehouse` — read/write of engagement data and ML feature tables
- `arbitrationPostgres` — upload target for ranking and STO scores (upload flows only)
- `gcpGcsBucket` — JAR artifact source, audience path CSV outputs, YATI streaming output

The Janus-YATI flow additionally spans `arbitration_log` Kafka topic (external) and `gcpGcsBucket` as the output sink.
