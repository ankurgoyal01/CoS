---
service: "gcp-aiaas-terraform"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumBigQuery"
    type: "bigquery"
    purpose: "Analytics warehouse for ML datasets and merchant data"
  - id: "continuumStorageBuckets"
    type: "gcs"
    purpose: "Object storage for DAGs, model artifacts, ETL data, and project files"
---

# Data Stores

## Overview

The AIaaS platform uses two primary storage tiers: GCP BigQuery as the analytics data warehouse for structured ML datasets and results, and GCP Cloud Storage as the object store for unstructured data (DAG files, ML model artifacts, ETL inputs/outputs, and project configuration files). Both are provisioned via Terraform modules (`gcp-big-query` and `gcp-buckets`). Runtime services (Cloud Run, Cloud Functions, Cloud Composer) access secrets from GCP Secret Manager, which acts as a configuration data store.

## Stores

### BigQuery — Merchant Data Center (`continuumBigQuery`)

| Property | Value |
|----------|-------|
| Type | BigQuery |
| Architecture ref | `continuumBigQuery` |
| Purpose | Centralised analytics warehouse for merchant data, Google Reviews, and AI/ML workflow results |
| Ownership | owned |
| Dataset ID | `merchant_data_center` |
| Location | US (multi-region) |
| Migrations path | `envs/dev/us-central1/gcp-big-query/terragrunt.hcl` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `merchant_center_table` | Centralised merchant data for AI/ML workflows and low-latency APIs | Merchant-level attributes (schema managed in Terraform module) |
| `google_reviews_raw_table` | Raw Google Reviews data ingested for merchant quality analysis | Review text, rating, merchant ID, ingestion timestamp |

#### Access Patterns

- **Read**: Cloud Run services and Cloud Functions query merchant and reviews data for inference; Cloud Composer DAGs read pipeline inputs
- **Write**: Cloud Run services and Cloud Functions write ML inference results; Cloud Composer orchestrates ETL writes for pipeline outputs
- **Indexes**: Managed by BigQuery natively; partition and clustering strategies are in the Terraform module (not visible in this repo's terragrunt config)

### Cloud Storage Buckets (`continuumStorageBuckets`)

| Property | Value |
|----------|-------|
| Type | GCP Cloud Storage (GCS) |
| Architecture ref | `continuumStorageBuckets` |
| Purpose | Object storage for DAGs, ETL data, ML model artifacts, and project files |
| Ownership | owned |
| Region | us-central1 |
| Migrations path | `envs/dev/us-central1/gcp-buckets/terragrunt.hcl` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `artifacts_bucket` | Stores compiled Cloud Function artifacts and build outputs | Function zip archives |
| `models_bucket` | Stores trained ML model files and weights | Model binaries, serialised model files |
| `data_bucket` | Stores ETL pipeline inputs and outputs | Structured data files (CSV, Parquet, JSON) |
| `project_file_bucket` | Stores permission files and project configuration artefacts | IAM policies, config files |
| DAGs bucket | Stores Airflow DAG Python files; synced to Cloud Composer | `.py` DAG files under `dags/` prefix |

#### Access Patterns

- **Read**: Cloud Functions and Cloud Run read model artifacts and input data during inference; Cloud Composer reads DAG files on deploy
- **Write**: Cloud Functions and Cloud Run write inference results and intermediate ETL outputs; CI/CD writes function zip archives to `artifacts_bucket`
- **Indexes**: Object listing is used for DAG discovery; no formal indexes (GCS flat namespace)

### Secret Manager (`continuumSecretManager`)

| Property | Value |
|----------|-------|
| Type | GCP Secret Manager |
| Architecture ref | `continuumSecretManager` |
| Purpose | Centralised secret injection for Cloud Run and Cloud Functions at runtime |
| Ownership | owned |
| Migrations path | `envs/dev/us-central1/gcp-secret-manager/terragrunt.hcl` |

#### Access Patterns

- **Read**: Cloud Run services and Cloud Functions call Secret Manager API at startup or on-demand to retrieve database credentials, API tokens, and service account keys
- **Write**: Secrets are provisioned/rotated via Terraform (`gcp-secret-manager` module); no application-level writes

## Caches

> No evidence found in codebase. No Redis, Memcached, or in-memory cache layer is provisioned in this repository.

## Data Flows

- Cloud Composer (Airflow) DAGs orchestrate ETL: reads raw data from `data_bucket` (GCS), processes via Dataproc (Spark), writes results to `merchant_data_center` dataset (BigQuery)
- Cloud Functions read inference inputs from `data_bucket` and write results back to BigQuery or return directly to API callers
- Cloud Run services write batch inference results to BigQuery (`merchant_data_center`) and store intermediate artifacts to `models_bucket`
- The `artifacts_bucket` acts as a deployment channel: CI/CD uploads Cloud Function zip archives there before Terraform references them during function provisioning
