---
service: "sem-gcp-pipelines"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSemGcpPipelinesComposer"
  containers: ["continuumSemGcpPipelinesComposer"]
---

# Architecture Context

## System Context

sem-gcp-pipelines sits within Groupon's **Continuum** platform as the SEM and Display Marketing pipeline orchestration system. It runs as a collection of Apache Airflow DAGs on GCP Composer, operating within the `us-central1` region. The service acts as a data processing hub: it pulls deal and merchant data from internal Groupon services (Deal Catalog, GAPI, Databreakers, Denylisting, Keyword Service, Marketing Deal Service), processes that data on ephemeral Dataproc clusters using PySpark and Java Spark jobs, and delivers the results to external ad platforms (Google Ads, Facebook Ads, Google Places, CSS Affiliates, Google Things To Do, Google Appointment Services). It also publishes keyword messages to the internal Groupon Message Bus for downstream SEM keyword management.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| SEM GCP Pipelines (Composer DAGs) | `continuumSemGcpPipelinesComposer` | Orchestration | Python / Airflow | GCP Composer 2.x | Airflow DAGs orchestrating SEM data pipelines, ad platform feeds, and monitoring jobs on GCP |

## Components by Container

### SEM GCP Pipelines (Composer DAGs) (`continuumSemGcpPipelinesComposer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Airflow DAGs | DAG definitions for SEM pipelines, ad platform feeds, and monitoring workflows | Python |
| Dataproc Orchestration | Creates and tears down Dataproc clusters; submits PySpark and Java Spark jobs | Python / Airflow Dataproc Operators |
| GCS Utilities | Reads and writes DAG artifacts, configs, and data in GCS buckets using `gsutil` | Python |
| External Service Clients | HTTP clients for internal APIs (Deal Catalog, GAPI, Databreakers, Denylisting, MDS, Keyword Service) using `hburllib` and `requests` | Python |
| Message Bus Publisher | Publishes keyword submission messages over STOMP to the internal Message Bus | Python / stomp.py |
| Secrets Access | Reads credentials and API keys from GCP Secret Manager via `gcloud` CLI | Python |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumSemGcpPipelinesComposer` | `messageBus` | Publishes keyword messages (deal_id, keywords, country, user) | STOMP |
| `continuumSemGcpPipelinesComposer` | `continuumDealCatalogService` | Fetches deal metadata via `/deal_catalog/v2/deals/{uuid}` | REST / mTLS |
| `continuumSemGcpPipelinesComposer` | `continuumMarketingDealService` | Dispatches feeds via `/dispatcher/feed/{uuid}` and uploads reports via `uploads/rich_relevance` | REST / mTLS |
| `continuumSemGcpPipelinesComposer` | `googleAds` | Syncs SEM feeds and campaigns | SFTP / API |
| `continuumSemGcpPipelinesComposer` | `facebookAds` | Syncs Facebook Display and Location feeds | Spark job / API |
| `continuumSemGcpPipelinesComposer` | `googlePlaces` | Fetches places data for Google Places feed generation | Spark job / API |
| `continuumSemGcpPipelinesComposer` | `gcpDataprocCluster_469e25` | Submits jobs and manages ephemeral clusters | GCP Dataproc API |
| `continuumSemGcpPipelinesComposer` | `gcsDagsBucket_c78c51` | Reads and writes DAG artifacts | GCS |
| `continuumSemGcpPipelinesComposer` | `gcsArtifactsBucket_aedc8c` | Reads and writes job artifacts (ZIP bundles from Artifactory) | GCS |
| `continuumSemGcpPipelinesComposer` | `gcsDataBucket_a28d89` | Reads and writes SEM data (Parquet, Hive-partitioned) | GCS |
| `continuumSemGcpPipelinesComposer` | `gcpSecretManager_cc4b72` | Reads secrets and credentials | gcloud CLI |
| `continuumSemGcpPipelinesComposer` | `databreakersService_eb0ade` | Fetches deal and recommendation data (HMAC-signed) | REST / HTTPS |
| `continuumSemGcpPipelinesComposer` | `denylistingService_5997c8` | Loads denylist terms for keyword filtering | REST / mTLS |
| `continuumSemGcpPipelinesComposer` | `keywordService_a38496` | Deletes keywords via `DELETE deals/keywords` | REST / mTLS |
| `continuumSemGcpPipelinesComposer` | `gapiService_76fbb4` | Fetches deal details for US/CA (NA) and EMEA countries | REST / mTLS |
| `continuumSemGcpPipelinesComposer` | `googleThingsToDo_b74080` | Publishes Things To Do feeds via MDS dispatcher | REST / SFTP |
| `continuumSemGcpPipelinesComposer` | `googleAppointment_ffa189` | Publishes appointment entity and action feeds | Spark job |
| `continuumSemGcpPipelinesComposer` | `cssAffiliates_59280e` | Publishes CSS affiliate product feeds for EU countries | Spark job |
| `continuumSemGcpPipelinesComposer` | `searchAds360_9fc4fa` | Syncs SA360 feeds and campaigns | Spark job |

## Architecture Diagram References

- System context: `contexts-semGcpPipelines`
- Container: `containers-semGcpPipelines`
- Component: `components-semGcpPipelinesComposer`
