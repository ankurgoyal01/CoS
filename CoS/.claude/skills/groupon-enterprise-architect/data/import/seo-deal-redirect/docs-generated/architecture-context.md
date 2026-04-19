---
service: "seo-deal-redirect"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - "continuumSeoDealRedirectDag"
    - "continuumSeoDealRedirectJobs"
    - "continuumSeoHiveWarehouse"
---

# Architecture Context

## System Context

SEO Deal Redirect is a batch pipeline within the Continuum platform's SEO domain. It sits entirely on GCP infrastructure and has no direct user-facing ingress. The pipeline is triggered on a daily schedule by GCP Cloud Composer (Airflow), provisions a transient Dataproc cluster, runs Hive and PySpark jobs against the shared SEO Hive metastore, and publishes results outbound to the `seo-deal-api` service over HTTPS. The `seo-deal-api` then propagates redirect attributes to the Deal Catalog, which serves deal pages to end users and search engine crawlers.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| SEO Deal Redirect DAG | `continuumSeoDealRedirectDag` | Workflow / Orchestrator | Python / Airflow (GCP Composer) | Airflow DAG that schedules and coordinates all Dataproc Hive and Spark jobs. Handles cluster lifecycle, date computation, and completion notifications. |
| SEO Deal Redirect Jobs | `continuumSeoDealRedirectJobs` | Batch Job Set | PySpark / Hive | Collection of Spark and Hive jobs that build redirect mappings and publish updates to the SEO Deal API. |
| SEO Hive Warehouse | `continuumSeoHiveWarehouse` | Database | Hive | Hive tables consumed and produced by the pipeline (`daily_deals`, `final_redirect_mapping`, staging tables, etc.). |

## Components by Container

### SEO Deal Redirect DAG (`continuumSeoDealRedirectDag`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Redirect Workflow DAG (`dagDefinition`) | Wires task dependencies and defines the daily schedule via `redirect_workflow.py` | Python / Airflow |
| Execution Date Resolver (`executionDateResolver`) | Computes `run_date`, `prev_date`, and `purge_date`; stores values in XCom for downstream tasks | Python |
| Dataproc Orchestrator (`dataprocOrchestrator`) | Creates the Dataproc cluster, submits Hive and Spark jobs, and deletes the cluster on completion | Airflow Dataproc Operators |
| Completion Notifier (`notificationSender`) | Sends job completion email to `computational-seo@groupon.com` via Airflow EmailOperator | Airflow EmailOperator |

### SEO Deal Redirect Jobs (`continuumSeoDealRedirectJobs`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Hive ETL Scripts (`hiveEtlScripts`) | HQL scripts that populate staging and mapping tables: exclusion loading, deal extraction, expired-to-live mapping, deduplication, cycle removal | HiveQL |
| API Upload Table Population Job (`apiUploadTablePopulation`) | PySpark job that builds `final_redirect_mapping` with fully-qualified live deal URLs (insert, update, delete actions) | PySpark |
| API Upload Job (`apiUploadJob`) | PySpark job that reads `final_redirect_mapping`, diffs against previous run, and HTTP PUT's new/changed redirects to the SEO Deal API | PySpark |
| Non-Active Merchant Deals Job (`nonActiveMerchantDealsJob`) | PySpark job that identifies deals whose merchants have no active deals, enriches with taxonomy/location data, and calls the SEO Deal API with redirect URLs | PySpark |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumSeoDealRedirectDag` | `continuumSeoDealRedirectJobs` | Schedules jobs and passes configuration via XCom | Airflow |
| `continuumSeoDealRedirectJobs` | `continuumSeoHiveWarehouse` | Reads and writes SEO Hive tables | Hive |
| `continuumSeoDealRedirectJobs` | `seoDealApi` (stub) | Updates redirect attributes for each expired deal | HTTPS PUT |
| `continuumSeoDealRedirectJobs` | `gcpDataproc` (stub) | Executes Spark and Hive workloads on provisioned clusters | Dataproc API |
| `continuumSeoDealRedirectJobs` | `gcpCloudStorage` (stub) | Reads/writes artifacts, Parquet files, and CSV reference data | GCS |

## Architecture Diagram References

- Container: `containers-seoDealRedirect`
- Component (DAG): `components-seoDealRedirectDag`
- Component (Jobs): `components-seoDealRedirectJobs`
