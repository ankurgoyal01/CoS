---
service: "gcp-aiaas-terraform"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the GCP AIaaS Terraform platform.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Synchronous AI Inference via API Gateway](api-gateway-inference.md) | synchronous | API call | External caller sends POST to `/v1/*` endpoint; API Gateway routes to Cloud Function for ML inference and returns result |
| [Scheduled Background Job via Cloud Scheduler and Cloud Tasks](scheduled-background-job.md) | scheduled | Schedule (cron) | Cloud Scheduler fires daily, enqueues Cloud Tasks item, Cloud Run processes batch job and writes results to BigQuery and GCS |
| [Airflow DAG Orchestrated Pipeline](airflow-dag-pipeline.md) | batch | Airflow DAG trigger | Cloud Composer runs a multi-step DAG: reads data from GCS/BigQuery, processes via Dataproc, writes results back to BigQuery |
| [Terraform Infrastructure Provisioning](terraform-provisioning.md) | synchronous | Manual / CI/CD (Jenkins) | Engineer runs Terragrunt plan/apply to provision or update GCP resources across dev or prod environments |
| [Async Background ML Processing Request](async-submit-request.md) | asynchronous | API call | Caller POSTs to `/v1/submitRequest`; Cloud Function enqueues background ML work for deferred processing |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **Scheduled Background Job** flow is documented in the Structurizr architecture dynamic view `dynamic-scheduled-workflow` and involves `continuumCloudScheduler`, `continuumCloudTasks`, `continuumCloudRunService`, `continuumBigQuery`, and `continuumStorageBuckets`
- The **Airflow DAG Pipeline** flow involves `continuumComposer`, `continuumBigQuery`, and `continuumStorageBuckets` as documented in the container relations in `architecture/models/relations.dsl`
