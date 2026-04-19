---
service: "gcp-aiaas-terraform"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumApiGateway"
    - "continuumCloudRunService"
    - "continuumCloudFunctionsGen2"
    - "continuumCloudScheduler"
    - "continuumCloudTasks"
    - "continuumComposer"
    - "continuumBigQuery"
    - "continuumStorageBuckets"
    - "continuumSecretManager"
    - "continuumVertexAi"
---

# Architecture Context

## System Context

`gcp-aiaas-terraform` provisions the infrastructure for Groupon's GCP AI-as-a-Service (AIaaS) platform, which lives within the `continuumSystem` software system in the C4 model. The platform sits at the intersection of Data Science workflows and production ML inference: external callers (internal services and Merchant Advisor tooling) reach ML endpoints via GCP API Gateway, while Cloud Composer orchestrates scheduled batch pipelines that read from and write to BigQuery and Cloud Storage. The Terraform/Terragrunt codebase does not run any application logic itself — it declaratively describes and provisions all GCP resources that host that logic.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| API Gateway | `continuumApiGateway` | Gateway | GCP API Gateway | managed | Front door for HTTP APIs; routes to Cloud Functions and Cloud Run backends using OpenAPI spec |
| Cloud Run Service | `continuumCloudRunService` | Compute | GCP Cloud Run | managed | Serverless container runtime for AIaaS inference services (e.g., image-extraction-api, aidg-top-deals) |
| Cloud Functions (Gen 2) | `continuumCloudFunctionsGen2` | Compute | GCP Cloud Functions Gen 2 | managed | Event-driven functions for ML inference tasks (mpp_google_reviews, usp_generation, content_generation, gen_ai, etc.) |
| Cloud Scheduler | `continuumCloudScheduler` | Scheduling | GCP Cloud Scheduler | managed | Managed cron scheduler; triggers periodic Cloud Tasks enqueue (e.g., aidg-top-deals-async at 00:00 UTC daily) |
| Cloud Tasks | `continuumCloudTasks` | Queue | GCP Cloud Tasks | managed | Asynchronous task queue; receives scheduled tasks and invokes Cloud Run jobs via HTTP |
| Cloud Composer | `continuumComposer` | Orchestration | GCP Cloud Composer (Airflow 2.6.3) | composer-2.6.6 | Managed Apache Airflow environment for DAG-based data pipeline orchestration |
| BigQuery | `continuumBigQuery` | Data | GCP BigQuery | managed | Analytics data warehouse; stores merchant data, Google Reviews, ML results (dataset: `merchant_data_center`) |
| Cloud Storage Buckets | `continuumStorageBuckets` | Storage | GCP Cloud Storage | managed | Object storage for DAGs, ETL inputs/outputs, ML model artifacts, and project files |
| Secret Manager | `continuumSecretManager` | Security | GCP Secret Manager | managed | Centralised secret store; Cloud Run and Cloud Functions read secrets at runtime |
| Vertex AI | `continuumVertexAi` | ML | GCP Vertex AI | managed | Managed ML platform; hosts model endpoints, batch transform jobs, and training pipelines |

## Components by Container

### API Gateway (`continuumApiGateway`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| OpenAPI spec (`doc/swagger.yml`) | Defines all API routes and their Cloud Functions backend addresses | Swagger 2.0 / GCP API Gateway |
| API Key auth | Enforces API key requirement on all gateway routes | GCP API Gateway security |

### Cloud Run Service (`continuumCloudRunService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| image-extraction-api | Extracts and scores merchant images | Docker container on Cloud Run |
| aidg-top-deals | Generates top deals; invoked on schedule via Cloud Tasks | Docker container on Cloud Run |

### Cloud Functions Gen 2 (`continuumCloudFunctionsGen2`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| health_check | Platform health probe | GCP Cloud Function |
| mpp_google_reviews | Analyses Google Reviews for merchant quality | GCP Cloud Function |
| mpp_image_urls | Generates image quality scores | GCP Cloud Function |
| usp_generation | Generates Unique Selling Propositions for merchants | GCP Cloud Function |
| content_generation | Generates merchant content copy | GCP Cloud Function |
| gen_ai | General GenAI inference endpoint | GCP Cloud Function |
| analyze_grpn_reviews | Analyses Groupon-native merchant reviews | GCP Cloud Function |
| get_cdn_image_urls | Retrieves CDN image URLs for a merchant | GCP Cloud Function |
| delete_cdn_image_url | Removes CDN image URL entries | GCP Cloud Function |
| submit_request | Submits requests for background ML processing | GCP Cloud Function |
| dummy_inferpds / infer_pds | PDS model inference (stub) | GCP Cloud Function |
| dummy_inferece / infer_ece | ECE model inference (stub) | GCP Cloud Function |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumApiGateway` | `continuumCloudRunService` | Routes HTTP requests to Cloud Run backends | HTTPS |
| `continuumApiGateway` | `continuumCloudFunctionsGen2` | Routes HTTP requests to Cloud Function backends | HTTPS |
| `continuumCloudScheduler` | `continuumCloudTasks` | Enqueues scheduled tasks (cron-triggered) | GCP internal |
| `continuumCloudTasks` | `continuumCloudRunService` | Invokes background jobs via HTTP | HTTPS |
| `continuumCloudRunService` | `continuumSecretManager` | Reads runtime secrets | GCP SDK |
| `continuumCloudFunctionsGen2` | `continuumSecretManager` | Reads runtime secrets | GCP SDK |
| `continuumCloudRunService` | `continuumStorageBuckets` | Reads/writes objects (artifacts, models, data) | GCP SDK |
| `continuumCloudFunctionsGen2` | `continuumStorageBuckets` | Reads/writes objects | GCP SDK |
| `continuumCloudRunService` | `continuumBigQuery` | Reads/writes ML datasets and results | GCP SDK |
| `continuumCloudFunctionsGen2` | `continuumBigQuery` | Reads/writes ML datasets and results | GCP SDK |
| `continuumCloudRunService` | `continuumVertexAi` | Calls Vertex AI model endpoints for inference | HTTPS / GCP SDK |
| `continuumCloudFunctionsGen2` | `continuumVertexAi` | Calls Vertex AI model endpoints for inference | HTTPS / GCP SDK |
| `continuumComposer` | `continuumBigQuery` | Orchestrates data pipeline reads/writes | GCP SDK (Airflow operators) |
| `continuumComposer` | `continuumStorageBuckets` | Reads/writes pipeline DAG files and artifacts | GCP SDK (Airflow operators) |

## Architecture Diagram References

- Container view: `containers-gcp-aiaas`
- Dynamic scheduled workflow: `dynamic-scheduled-workflow`
