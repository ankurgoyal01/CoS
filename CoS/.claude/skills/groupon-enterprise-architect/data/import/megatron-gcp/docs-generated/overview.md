---
service: "megatron-gcp"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Ingestion / ETL"
platform: "GCP (Continuum)"
team: "DnD Ingestion"
status: active
tech_stack:
  language: "Python"
  language_version: "3.8.12"
  framework: "Apache Airflow"
  framework_version: "2.10.5"
  runtime: "Docker / GCP Cloud Composer"
  runtime_version: "Composer 2.x"
  build_tool: "Jenkins (dataPipeline DSL)"
  package_manager: "pip"
---

# Megatron GCP Overview

## Purpose

Megatron GCP is the Google Cloud migration layer for Groupon's on-premises MySQL and PostgreSQL data pipelines. It generates Apache Airflow DAGs from YAML configuration files, then orchestrates full-lifecycle data ingestion (sqoop extract, load, merge, full-load) onto Dataproc clusters, writing final data to Teradata and BigQuery. The service also runs automated audit and validation DAGs that cross-check row counts, schema compatibility, and data freshness across source and destination systems.

## Scope

### In scope
- DAG code generation from YAML service and partition configurations (`mysql_dag_factory_config.yaml`, `postgres_dag_factory_config.yaml`)
- Dataproc cluster lifecycle management (create, configure, delete) per pipeline run
- Four ingestion modes: `sqoop`, `load`, `merge`, `full_load`
- Post-ingestion validation: Hive row counts, MySQL source counts, BigQuery counts, Teradata counts, final reconciliation
- BigQuery data-quality framework: table existence, schema compatibility, record-count analysis, primary-key overlap, sample-record integrity, data freshness
- Secrets and config distribution to Dataproc cluster nodes via GCS and GCP Secret Manager
- ETL process-status tracking via `megatron_etl_process_status` SQL connection

### Out of scope
- Source database schema management (owned by upstream service teams)
- Teradata schema DDL (managed by the data warehouse team)
- Dataproc custom image builds (handled in a separate compute image pipeline)
- Airflow cluster provisioning (managed via GCP Cloud Composer)

## Domain Context

- **Business domain**: Data Ingestion / ETL — migrating on-prem OLTP databases to GCP cloud storage and analytics layers
- **Platform**: Continuum (GCP data layer)
- **Upstream consumers**: Data analysts, BI tools, and downstream data products that query Teradata (`meg_grp_prod`) and BigQuery datasets
- **Downstream dependencies**: GCP Dataproc, GCS, GCP Secret Manager, BigQuery, Teradata, `megatron_etl_process_status` database, metric gateway (Telegraf/InfluxDB)

## Stakeholders

| Role | Description |
|------|-------------|
| DnD Ingestion Team | Service owners; manage DAG configs and pipeline ops |
| Data Consumers | BI/analytics teams relying on ingested Teradata/BigQuery tables |
| SRE / Ops | Monitor pipeline health via Slack channel `dnd-ingestion-ops` |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.8.12 | `Dockerfile` (`FROM docker.groupondev.com/python:3.8.12`) |
| Framework | Apache Airflow | 2.10.5 (constraints) | `Dockerfile` (constraint URL) |
| GCP Operators | apache-airflow-providers-google | latest (Airflow-constrained) | `dag_generator/requirements.txt` |
| Container | Docker | — | `Dockerfile` |
| CI/CD | Jenkins dataPipeline DSL | — | `Jenkinsfile` |
| Config format | YAML | — | `orchestrator/megatron/dag_config/*.yaml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `apache-airflow` | 2.10.5 (constrained) | scheduling | DAG definition and task orchestration |
| `apache-airflow-providers-google` | latest | message-client | DataprocSubmitJobOperator, DataprocDeleteClusterOperator, BigQuery API |
| `pyyaml` | latest | serialization | Reads YAML DAG-factory and service config files |
| `preutils` (Impl) | internal | logging | `trigger_event` / `resolve_event` failure and success callbacks |
| `tungsten_merge` | internal | db-client | Per-table ingestion/merge module invoked as Python module on Dataproc |
| `megatron_util` | internal | scheduling | Cluster-needed check, job status polling, `_finally` DAG callback |
| `zombie_runner` | internal | auth | ZRC2 credential handling on Dataproc nodes |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
