---
service: "magneto-gcp"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Ingestion — Salesforce to Hive"
platform: "Continuum (GCP Data Platform)"
team: "dnd-ingestion"
status: active
tech_stack:
  language: "Python"
  language_version: "3.8.12"
  framework: "Apache Airflow"
  framework_version: "2.10.5"
  runtime: "Docker / Kubernetes"
  runtime_version: "GCP Stable / Production"
  build_tool: "Jenkins (dataPipeline DSL)"
  package_manager: "pip"
---

# magneto-gcp Overview

## Purpose

magneto-gcp is a Salesforce Data Ingestion Automation framework. It programmatically generates Apache Airflow DAG definitions from YAML table configuration and then orchestrates the full incremental ETL cycle: extracting records from Salesforce objects, staging them in Google Cloud Storage, loading them into Hive tables on Google Cloud Dataproc, and updating watermark state in a MySQL table-limits store. The framework separates DAG code generation (a build-time step) from DAG runtime execution (Airflow/Dataproc), enabling new Salesforce objects to be onboarded by adding configuration entries without modifying pipeline code.

## Scope

### In scope

- Generating Airflow DAG Python files from per-table YAML configuration (SOX and NON-SOX compliance paths)
- Generating validation/audit DAG files that compare Salesforce row counts with Hive table counts
- Running the generated ingestion DAGs: provisioning ephemeral Dataproc clusters, copying GCP secrets, preprocessing schema changes, extracting Salesforce data, loading to Hive, and deleting clusters
- Schema drift detection and automatic ALTER TABLE column additions on Hive target tables
- GDPR field exclusion during extraction (via `table_limits` MySQL database query)
- Watermark management: reading `consistent_before_soft` from `table_limits` and updating it after each load
- Ingestion lag metrics published to the Telegraf/InfluxDB metrics gateway
- Dataproc custom image lifecycle management (auto-renewal DAG)

### Out of scope

- Serving query results to downstream consumers (read from Hive directly)
- Defining Salesforce object schemas (owned by Salesforce)
- Managing the Hive metastore cluster itself (owned by GCP / Dataproc Metastore)
- Creating the initial Hive target tables (pre-existing DDL)
- Full historical loads / restatements (orchestrated externally)

## Domain Context

- **Business domain**: Data Ingestion — Salesforce to Hive/Dataproc on GCP
- **Platform**: Continuum (GCP Data Platform)
- **Upstream consumers**: Downstream analytics and data warehouse consumers reading from Hive/Dataproc tables (e.g., `dwh_manage.table_limits`)
- **Downstream dependencies**: Salesforce API (object extraction), Google Cloud Dataproc (ETL compute), Google Cloud Storage (staging), MySQL `table_limits` (watermark state), Telegraf/InfluxDB (metrics)

## Stakeholders

| Role | Description |
|------|-------------|
| Owner / On-call | dnd-ingestion team — Slack: `#dnd-ingestion-ops` |
| Audit email | magneto-audit-results@groupon.com (audit failure notifications sent to dnd-ingestion@groupon.com) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.8.12 | `Dockerfile` — `FROM docker.groupondev.com/python:3.8.12` |
| Framework | Apache Airflow | 2.10.5 | `dag_generator/requirements.txt` — `constraints-2.10.5` |
| Airflow provider | apache-airflow-providers-google | latest (constrained) | `dag_generator/requirements.txt` |
| Runtime | Docker on Kubernetes (GCP) | GCP Stable/Prod | `Dockerfile`, `.deploy_bot.yml` |
| Build tool | Jenkins (dataPipeline DSL) | java-pipeline-dsl@dpgm-1396 | `Jenkinsfile` |
| Package manager | pip | — | `dag_generator/requirements.txt` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `apache-airflow` | 2.10.5 (constrained) | scheduling | Workflow orchestration, DAG runtime |
| `apache-airflow-providers-google` | latest | scheduling | `DataprocSubmitJobOperator`, `DataprocDeleteClusterOperator` |
| `pyyaml` | latest | serialization | Parse `config.yaml` and `dag_factory_config.yaml` |
| `simple-salesforce` | latest | db-client | Salesforce SOQL query execution and metadata inspection |
| `google-cloud-storage` | latest | db-client | GCS blob read/write for staged extract files and YAML configs |
| `mysql-connector-python` | latest | db-client | ODBC/MySQL connection to `table_limits` and GDPR column metadata |
| `influxdb` | latest | metrics | Push ingestion lag metrics to Telegraf/InfluxDB gateway |
| `zombie_runner` | internal | scheduling | Run extract/load YAML task graphs on Dataproc nodes |
| `jinja2` | latest | serialization | Template rendering in metric DAG |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
