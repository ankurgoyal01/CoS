---
service: "mis-data-pipelines-dags"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Marketing Intelligence / Data Engineering"
platform: "GCP Cloud Composer"
team: "MIS Engineering"
status: active
tech_stack:
  language: "Python"
  language_version: "3.x"
  framework: "Apache Airflow"
  framework_version: "2.x (Cloud Composer)"
  runtime: "GCP Cloud Composer"
  runtime_version: "Cloud Composer 2"
  build_tool: "Jenkins (java-pipeline-dsl shared library)"
  package_manager: "pip (via Cloud Composer environment)"
---

# MIS Data Pipelines DAGs Overview

## Purpose

`mis-data-pipelines-dags` is an Apache Airflow DAG repository that orchestrates the Marketing Intelligence Service (MIS) data pipelines running on Google Cloud Platform. It manages ephemeral and persistent Dataproc clusters, submits Spark/Hive jobs, and coordinates data archival, deal performance aggregation, Janus Kafka streaming, backfill, and Bloomreach CDP feed cleanup workflows. The service is the scheduling and orchestration backbone that moves deal and marketing data from source systems (MDS API, Kafka, Hive/EDW) into GCS buckets, Hive tables, and PostgreSQL stores for downstream analytics and reporting.

## Scope

### In scope

- Scheduling and orchestrating Airflow DAGs via GCP Cloud Composer for all MIS data pipelines
- Creating and managing ephemeral GCP Dataproc clusters for Spark and Hive workloads
- Archiving MDS deal data from the Marketing Deal Service API into GCS and Hive partitions (NA, EMEA, APAC regions)
- Running data quality checks on archived deal partitions using the CDE Spark data quality framework
- Executing deal performance ingestion, bucketing (hourly/daily), and export pipelines via Spark
- Running the Janus Spark Streaming job that consumes Kafka tier-2 events and enqueues deal IDs into Redis
- Running the MDS Backfill job that seeds newly active deals from Hive into Redis for batch processing
- Executing the Deals Cluster job to cluster active deals based on configurable rules
- Ingesting deal attribute data via the deal-attribute aggregation pipeline
- Refreshing Tableau dashboard Hive tables and triggering Tableau extract refreshes
- Cleaning up old GCS files and Hive partitions for archival and DPS data
- Cleaning up stale Bloomreach SEM/CDP feed files from GCS
- Managing TLS certificate initialization for Janus Spark clusters

### Out of scope

- Serving the MDS deal data API (owned by `continuumMarketingDealService`)
- Consuming Kafka events directly — Janus streaming is delegated to the `mds-janus` Spark assembly jar
- Owning or managing the EDW/Hive data warehouse schema (owned by the data platform team)
- Serving downstream reporting UI (owned by Tableau and BI tooling)
- Managing Redis directly — Redis queue population is a side-effect of the Janus and Backfill Spark jobs

## Domain Context

- **Business domain**: Marketing Intelligence / Data Engineering
- **Platform**: GCP Cloud Composer (Apache Airflow) + GCP Dataproc
- **Upstream consumers**: Tableau dashboards (via Hive/EDW), downstream ML/analytics pipelines, Bloomreach CDP feeds
- **Downstream dependencies**: `continuumMarketingDealService` (MDS API), Kafka/MSK (Janus tier-2 topic), EDW/Hive tables, GCS buckets, GCP Dataproc, GCP Metastore, BigQuery

## Stakeholders

| Role | Description |
|------|-------------|
| MIS Engineering | Owns and maintains all DAGs, Spark job configs, and archival scripts |
| Data Platform / EDW | Owns the Hive/EDW schema that pipelines read from and write to |
| Marketing Analytics | Primary consumer of deal performance, archival, and Tableau outputs |
| Bloomreach / SEM team | Consumers of CDP feed GCS outputs managed by cleanup DAGs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.x | `orchestrator/bloomreach_sem_cdp_feeds_cleanup.py` |
| Framework | Apache Airflow | 2.x | `from airflow import DAG` in DAG files |
| Runtime | GCP Cloud Composer | 2 | `COMPOSER_DAGS_BUCKET` in `.deploy_bot.yml` |
| Build tool | Jenkins (java-pipeline-dsl@dpgm-1396-pipeline-cicd) | — | `Jenkinsfile` |
| Compute | GCP Dataproc | 1.5-debian10, 2.2.51-debian12 | cluster `software_config.image_version` in job configs |
| Workflow runner | Zombie Runner | — | `mds-archive/production.zrc2`, `zombie_runner run` calls |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `apache-airflow` | 2.x | scheduling | DAG definition, scheduling, task execution |
| `apache-airflow-providers-google` | — | cloud | `DataprocSubmitJobOperator`, `DataprocCreateClusterOperator` |
| `mds-janus_2.12` | 1.1.52 | message-client | Spark Streaming job reading Janus Kafka tier-2 events |
| `mds-backfill_2-4-8_2.12` | 1.0.4 | batch | Backfill job seeding Redis from active_deals Hive table |
| `deals-cluster` | 1.83 | batch | Deals clustering Spark job using configurable rules |
| `deal-performance-data-ingestion-pipelines_2-4-8_2.12` | 1.1.2 | batch | Deal performance data ingestion into Hive |
| `deal-performance-data-pipelines-cloud` | 3.7 | batch | Deal performance bucketing and export (Spark/Beam) |
| `deal-attribute-data-ingestion-pipeline_2-4-8_2.12` | 1.2.4 | batch | Deal attribute aggregation pipeline |
| `cde-spark_2.12` | 1.0.8 | data-quality | CDE Spark data quality checks on archived partitions |
| `json-serde` | 1.3.8 | serialization | JSON SerDe for Hive table operations |
| `json-udf` | 1.3.8 | serialization | JSON UDF functions for Hive queries |
| `zombie_runner` | — | scheduling | Workflow orchestration for archival shell/HQL tasks on Dataproc |
