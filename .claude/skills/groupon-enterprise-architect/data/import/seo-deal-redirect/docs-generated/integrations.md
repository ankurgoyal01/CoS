---
service: "seo-deal-redirect"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

SEO Deal Redirect has one declared internal dependency (`seo-deal-api`) and three GCP platform dependencies (Cloud Composer, Dataproc, Cloud Storage). All outbound integration is via HTTPS PUT (to the SEO Deal API) or GCP native APIs. The service reads source data from shared EDW Hive databases and writes back to its own SEO Hive namespace. There are no inbound API integrations — this service is not called by other services.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Cloud Composer (Airflow) | GCP managed | Orchestrates DAG scheduling and task execution | yes | `gcpDataproc` (stub) |
| GCP Dataproc | Dataproc API | Provisions transient Spark/Hive clusters for each DAG run | yes | `gcpDataproc` (stub) |
| GCP Cloud Storage | GCS API | Stores reference CSVs, Parquet artifacts, init scripts | yes | `gcpCloudStorage` (stub) |
| GCP Secret Manager | GCP API | Provides TLS keystore secret (`tls--seo-seo-deal-redirect`) at cluster init | yes | — |

### GCP Dataproc Detail

- **Protocol**: GCP Dataproc API (via Airflow Dataproc operators)
- **Base URL / SDK**: Airflow `DataprocCreateClusterOperator`, `DataprocSubmitJobOperator`
- **Auth**: GCP service account `loc-sa-c-seo-dataproc@prj-grp-c-common-prod-ff2b.iam.gserviceaccount.com`
- **Purpose**: Creates a transient Dataproc cluster (1 master + 2 workers, `n1-standard-8`) to run Hive and PySpark jobs; deletes the cluster after the DAG run completes
- **Failure mode**: If cluster creation fails, the entire DAG run fails; no fallback
- **Circuit breaker**: None configured

### GCP Cloud Storage Detail

- **Protocol**: GCS API (via `gsutil` and Spark `read`/`write`)
- **Base URL / SDK**: `gs://us-central1-grp-shared-comp-9260309b-bucket/` (production DAGs bucket); `gs://grpn-dnd-prod-analytics-common/` (shared artifacts)
- **Auth**: GCP service account with storage read/write permissions
- **Purpose**: Hosts DAG Python files, reference data CSVs, Parquet output for `final_redirect_mapping`, and cluster init scripts
- **Failure mode**: Spark jobs fail if required GCS paths are unavailable
- **Circuit breaker**: None configured

### GCP Secret Manager Detail

- **Protocol**: GCP Secret Manager API
- **Base URL / SDK**: `google-cloud-secret-manager==1.0.1`
- **Auth**: GCP service account
- **Purpose**: Loads TLS keystore (`tls--seo-seo-deal-redirect` / `seo-deal-redirect-keystore.jks`) at Dataproc cluster initialization via `load-certificates.sh` init action
- **Failure mode**: Cluster init fails if secret is unavailable; API upload cannot authenticate
- **Circuit breaker**: None configured

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `seo-deal-api` | HTTPS PUT | Receives redirect URL updates for expired deal UUIDs; propagates to Deal Catalog | `seoDealApi` (stub) |

### seo-deal-api Detail

- **Protocol**: REST (HTTPS PUT)
- **Base URL**: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` (production); `seo-deal-observer-staging-vip.snc1` (staging)
- **Host header**: `seo-deal-api.production.service`
- **Auth**: Mutual TLS — client certificate and private key extracted from PKCS12/JKS keystore using `pyOpenSSL`
- **Purpose**: Updates the `redirectUrl` attribute on each expired deal's SEO data record; the API forwards changes to the Deal Catalog service
- **Failure mode**: Individual PUT failures are logged and skipped; the job continues. A non-200 status is logged but does not abort the batch run.
- **Circuit breaker**: None — rate limiting (`ratelimit` library) prevents API overload but there is no circuit breaker for sustained failures

### Source Data Dependencies (Hive / EDW)

| Database | Purpose |
|----------|---------|
| `edwprod.ods_deal` | Master deal records (status, merchant linkage) |
| `edwprod.ods_merch_product` | Merchant product/category data |
| `dw.mv_dim_pds_grt_map` | PDS-to-GRT category mapping |
| `edwprod.redemption_location_unity` | Deal redemption location (lat/lng, locality) |
| `svc_goods_bundling_db` (`goods_db`) | NA goods bundled deal redirects |
| `grp_gdoop_gods_db` (`goods_emea_db`) | EMEA goods deal redirects |

## Consumed By

> Upstream consumers are tracked in the central architecture model. This service is a batch pipeline and does not expose an inbound API. The downstream consumers of its output are:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `seo-deal-api` | HTTPS (receives PUT) | Propagates redirect URL attributes to the Deal Catalog |
| Deal Catalog service | — (internal to seo-deal-api) | Stores `redirectUrl` on deal records; serves redirects to deal pages |

## Dependency Health

- **seo-deal-api**: No health check endpoint is called before upload. The `api_upload` job detects failures via HTTP response codes. A sustained failure would leave previously-published redirects unchanged (no rollback mechanism).
- **GCP Dataproc**: Cluster availability is checked implicitly by the Dataproc create-cluster operator; DAG alerts fire on cluster creation failure.
- **EDW Hive tables**: No explicit availability check; Hive query failures propagate as Airflow task failures and alert the team.
