---
service: "bq_orr"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Engineering / Data Warehouse"
platform: "Continuum / GCP Data Platform"
team: "EDW Admin (edw-admin@groupon.com)"
status: active
tech_stack:
  language: "Python"
  language_version: "3"
  framework: "Apache Airflow"
  framework_version: ""
  runtime: "Google Cloud Composer"
  runtime_version: ""
  build_tool: "Jenkins"
  package_manager: ""
---

# BigQuery Orchestration Service Overview

## Purpose

The BigQuery Orchestration Service (`bq_orr`) is a repository-managed Apache Airflow DAG package that packages, deploys, and executes data warehouse workloads against Google BigQuery. It provides Groupon's data engineering team with a CI/CD-backed workflow for promoting Airflow DAGs across dev, staging, and production Composer environments. The service acts as the operational layer between version-controlled pipeline definitions and the shared Google Cloud Composer runtime.

## Scope

### In scope

- Defining and versioning Apache Airflow DAGs in the `orchestrator/` directory
- Packaging DAG artifacts and deploying them to GCS-backed Composer DAG buckets via `deploybot_gcs`
- Managing per-environment deployment configuration (dev, staging, production) through `.deploy_bot.yml`
- CI/CD promotion path: dev → staging → production

### Out of scope

- Management or provisioning of the shared Google Cloud Composer environments (owned by `pre-gcp-composer`)
- Administration of Google BigQuery datasets, tables, or schemas (owned by Google Cloud Platform / data teams)
- Broader ETL/ELT pipeline logic beyond the DAG definitions stored in this repository
- Serving any synchronous HTTP API surface

## Domain Context

- **Business domain**: Data Engineering / Data Warehouse
- **Platform**: Continuum (GCP Data Platform)
- **Upstream consumers**: Data engineering teams and analysts who trigger or schedule Airflow DAGs
- **Downstream dependencies**: Google Cloud Composer runtime (`preGcpComposerRuntime`), Google BigQuery (`bigQuery`)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | rpadala — primary point of contact |
| Team Email | edw-admin@groupon.com — EDW admin team |
| GCP Support | Google Premium Support (P1–P4) — for BigQuery/Composer platform issues |
| Slack Channel | grim---pit (deployment notifications); rma-pipeline-notifications (dev deployments) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3 | `orchestrator/hello_world.py`, `orchestrator/hello_world2.py` |
| Framework | Apache Airflow | Not pinned in repo | `orchestrator/hello_world.py` (`from airflow import DAG`) |
| Runtime | Google Cloud Composer | Shared environment | `.deploy_bot.yml` (`kubernetes_cluster: gcp-stable-us-central1`) |
| Build tool | Jenkins | dataPipeline shared library (`dpgm-1396-pipeline-cicd`) | `Jenkinsfile` |
| Deployment image | deploybot_gcs | v3.0.0 | `.deploy_bot.yml` (`docker.groupondev.com/dnd_gcp_migration_tooling/deploybot_gcs:v3.0.0`) |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| apache-airflow | Not pinned | scheduling | DAG definition and task orchestration |
| airflow.operators.python_operator | (bundled with Airflow) | scheduling | Executes Python callables as Airflow tasks |

> Only the most important libraries are listed here — the ones that define how the service works. No `requirements.txt` or `pyproject.toml` was found in this repository; library versions are inferred from import statements.
