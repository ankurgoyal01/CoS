---
service: "bq_orr"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "bigQuery"
    type: "bigquery"
    purpose: "Target data warehouse for workloads orchestrated by DAGs in this repository"
---

# Data Stores

## Overview

The BigQuery Orchestration Service (`bq_orr`) does not own any data stores. It orchestrates workloads against Google BigQuery, which is a fully managed, serverless data warehouse owned and operated by Google Cloud Platform. DAG artifacts are staged to GCS-backed Cloud Composer DAG buckets as part of the CI/CD deployment flow, but those buckets are owned and managed by the shared `pre-gcp-composer` environment, not by this service.

## Stores

### Google BigQuery (`bigQuery`)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `bigQuery` (stub — external dependency, not in federated model) |
| Purpose | Target data warehouse where DAG-orchestrated workloads execute queries and process data |
| Ownership | external (Google Cloud Platform) |
| Migrations path | Not applicable — schema management is outside the scope of this repository |

#### Key Entities

> No evidence found in codebase.

BigQuery dataset and table definitions are not maintained in this repository. Schema management belongs to the data engineering and analytics teams.

#### Access Patterns

- **Read**: DAGs query BigQuery tables via the BigQuery API, mediated by Cloud Composer's Airflow workers.
- **Write**: DAGs write query results or transformed data back to BigQuery tables via the BigQuery API.
- **Indexes**: Not applicable — BigQuery uses columnar storage with partitioning and clustering rather than traditional indexes.

### GCS Composer DAG Buckets (deployment staging)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `preGcpComposerRuntime` (stub) |
| Purpose | Staging location for DAG artifact files uploaded by `deploybot_gcs` during CI/CD |
| Ownership | shared (managed by `pre-gcp-composer` environment) |
| Migrations path | Not applicable |

#### Access Patterns

- **Write**: `deploybot_gcs` uploads DAG Python files to the environment-specific GCS bucket during CI/CD deployment.
- **Read**: Cloud Composer runtime reads DAG files from the GCS bucket and loads them into the Airflow scheduler.

## Caches

> No evidence found in codebase.

No caches are configured or owned by this service.

## Data Flows

DAG Python files flow from this repository through the CI/CD pipeline (Jenkins / `deploybot_gcs`) into GCS-backed Composer DAG buckets. Cloud Composer picks up the files, loads them into the Airflow scheduler, and executes the defined tasks against Google BigQuery. No data is persisted by this service directly.
