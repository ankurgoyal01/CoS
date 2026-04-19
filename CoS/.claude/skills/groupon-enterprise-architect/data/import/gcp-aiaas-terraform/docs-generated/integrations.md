---
service: "gcp-aiaas-terraform"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 3
---

# Integrations

## Overview

The AIaaS platform integrates primarily with managed GCP services (Vertex AI, BigQuery, Cloud Storage, Secret Manager) and with one external database (a PostgreSQL DAAS instance operated by a separate Groupon team). All integrations from Cloud Run and Cloud Functions to GCP services use the GCP SDK with IAM service account authentication. The API Gateway integration uses the OpenAPI `x-google-backend` extension to forward requests to Cloud Function endpoints. Monitoring integrates with Wavefront (metrics) and PagerDuty (alerting).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Vertex AI | GCP SDK / HTTPS | Hosts and serves ML model endpoints for inference | yes | `continuumVertexAi` |
| GCP BigQuery | GCP SDK | Reads and writes ML datasets and merchant data | yes | `continuumBigQuery` |
| DAAS PostgreSQL | TCP / PostgreSQL wire protocol | Reads nearest top-deals data for `gcp-cloud-functions-2` | yes | N/A |
| Wavefront | HTTPS metrics push | Platform observability and alerting dashboard | no | N/A |

### GCP Vertex AI Detail

- **Protocol**: GCP SDK / HTTPS
- **Base URL / SDK**: GCP Vertex AI managed endpoints (`us-central1`)
- **Auth**: IAM service account `loc-sa-vertex-ai-pipeline@prj-grp-aiaas-prod-0052.iam.gserviceaccount.com`
- **Purpose**: Cloud Run services and Cloud Functions call Vertex AI endpoints to run model inference (predictions, batch transforms)
- **Failure mode**: Inference requests fail; Cloud Run or Cloud Function returns a 424 or 503 to the API Gateway caller
- **Circuit breaker**: No evidence found in codebase

### GCP BigQuery Detail

- **Protocol**: GCP SDK (BigQuery client library)
- **Base URL / SDK**: GCP BigQuery managed service, project `prj-grp-aiaas-prod-0052`, dataset `merchant_data_center`
- **Auth**: IAM service account
- **Purpose**: Stores and retrieves structured merchant data, Google Reviews, and ML inference results
- **Failure mode**: Pipeline steps fail; Airflow marks DAG tasks as failed and retries per DAG retry configuration
- **Circuit breaker**: No evidence found in codebase

### DAAS PostgreSQL Detail

- **Protocol**: TCP / PostgreSQL wire protocol (port 5432)
- **Base URL / SDK**: `aidg-service-ro-na-staging-db.gds.stable.gcp.groupondev.com` (staging hostname; prod host not visible in this repo)
- **Auth**: Username/password (`aidg_stg_dba` user for staging); credentials injected via Terragrunt inputs
- **Purpose**: `gcp-cloud-functions-2` module reads nearest top-deals data from the AIDG (AI Deal Generation) service database
- **Failure mode**: `nearest_top_deals` Cloud Function fails; returns error to caller
- **Circuit breaker**: No evidence found in codebase

### Wavefront Detail

- **Protocol**: HTTPS metrics push
- **Base URL / SDK**: `https://groupon.wavefront.com/dashboards/dssi-ml-toolkit`
- **Auth**: Configured externally (not in this repo)
- **Purpose**: Receives CPU, memory, disk, and Airflow scheduler heartbeat metrics from the platform; drives PagerDuty alerts
- **Failure mode**: Monitoring blind spot; no functional impact on the platform itself
- **Circuit breaker**: Not applicable

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| CloudCore `gcp-terraform-base` | Terragrunt module-ref | Provides reusable Terraform modules for all GCP resource types | N/A |
| AIDG (AI Deal Generation) service | PostgreSQL | Source of deal data consumed by `gcp-cloud-functions-2` | N/A |
| Groupon Shared VPC | GCP VPC peering | Provides private networking for Cloud Composer and Cloud Run (`vpc_connector`) | N/A |

### CloudCore `gcp-terraform-base` Detail

- **Protocol**: Terragrunt `module-ref` (resolves git-tagged module source at plan/apply time)
- **Purpose**: Provides all reusable Terraform modules (`gcp-cloud-functions`, `gcp-cloud-run`, `gcp-composer`, `gcp-buckets`, `gcp-api-gateway`, `gcp-cloud-task`, `gcp-cloud-scheduler`, `gcp-vertex-ai`, `gcp-secret-manager`, `gcp-big-query`) from `github.groupondev.com/CloudCore/gcp-terraform-base`
- **Evidence**: All `terragrunt.hcl` files use `run_cmd(".terraform-tooling/bin/module-ref", "<module-name>")`

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Merchant Advisor team tooling | HTTPS via API Gateway | Calls `/v1/*` AI inference endpoints to power merchant-facing features |
| Internal Data Science teams | Terraform/Terragrunt CLI | Deploys and manages their own Cloud Functions and Cloud Run services on the platform |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- **Wavefront** monitors platform health: Airflow scheduler heartbeat, CPU, memory, and disk are all alerted via PagerDuty (`PREMYX7`)
- **GCP managed services** (Vertex AI, BigQuery, Cloud Composer) are covered by GCP's standard SLA of 99.9% monthly uptime
- **Retry**: Cloud Composer Airflow DAGs retry failed tasks per per-DAG retry configuration; no explicit retry is configured in the Terraform layer
- **Health endpoint**: `/v1/healthCheck` (GET) on the API Gateway is used as the platform heartbeat probe
