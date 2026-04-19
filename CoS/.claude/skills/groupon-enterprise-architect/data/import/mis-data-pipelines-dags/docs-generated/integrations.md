---
service: "mis-data-pipelines-dags"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 3
---

# Integrations

## Overview

`mis-data-pipelines-dags` is an outbound-only orchestration service with no inbound callers. It integrates with four GCP platform services (Dataproc, GCS, Metastore, BigQuery) as external infrastructure dependencies, and three internal Groupon services (Marketing Deal Service API, Kafka/MSK message bus, and the Enterprise Data Warehouse). All integrations are initiated by Airflow DAG tasks running in Cloud Composer. TLS mutual authentication is used for Kafka (Janus cluster) and certificate-based auth for the MDS API calls from archival scripts.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Dataproc | GCP REST API | Creates and manages ephemeral/persistent Dataproc clusters; submits Spark and Hive jobs | yes | `cloudPlatform` |
| GCS (Google Cloud Storage) | gsutil / GCP Storage API | Reads and writes deal archive files, DPS pipeline outputs, feed files, and initialization scripts | yes | `cloudPlatform` |
| GCP Dataproc Metastore | GCP Metastore API | Provides Hive metastore for all Dataproc clusters | yes | `cloudPlatform` |
| BigQuery | BigQuery API | Receives analytical pipeline outputs for downstream reporting | no | `bigQuery` |
| Tableau Refresh API | HTTP | Triggers extract refresh after Tableau Hive table updates | no | external |
| GCP Secret Manager | gcloud CLI | Retrieves TLS certificates and private keys for Kafka and MDS mTLS | yes | `cloudPlatform` |
| Artifactory | HTTPS | Downloads Spark assembly JARs at cluster initialization and job submission time | yes | external |

### GCP Dataproc Detail

- **Protocol**: GCP Dataproc REST API (via `DataprocCreateClusterOperator`, `DataprocSubmitJobOperator`)
- **Base URL / SDK**: `apache-airflow-providers-google` Dataproc operators; project `prj-grp-mktg-eng-prod-e034`, region `us-central1`, zone `us-central1-f`
- **Auth**: GCP service account `loc-sa-consumer-mds-dataproc@prj-grp-mktg-eng-prod-e034.iam.gserviceaccount.com`
- **Purpose**: Ephemeral cluster creation for each Spark job pipeline (Janus, Backfill, DPS, Deals Cluster, Deal Attribute) and persistent Zombie Runner clusters for archival workflows
- **Failure mode**: DAG retries; ephemeral clusters are auto-deleted after idle TTL (1h for most, 12h for MDS Feeds cluster); failed jobs alert via Slack (`mis-deployment` channel) and email (`mds-alerts@groupondev.opsgenie.net`)
- **Circuit breaker**: None detected; retry attempts configured per-cluster in Zombie Runner (`attempts: 1`)

### GCS (Google Cloud Storage) Detail

- **Protocol**: `gsutil` CLI and GCP Storage API
- **Base URL / SDK**: Bucket `grpn-dnd-prod-analytics-grp-mars-mds`, `grpn-dnd-prod-analytics-bloomreach-sem-cdp-feeds`, `grpn-dnd-prod-analytics-common`
- **Auth**: GCP service account (same as Dataproc)
- **Purpose**: Archive flat and compressed deal data files; store DPS pipeline outputs; host Spark initialization scripts and shared JARs
- **Failure mode**: Archival script retries `gsutil cp` on non-zero exit; `max_http_attempts: 3` for MDS download before upload
- **Circuit breaker**: None detected; retries handled in shell scripts

### GCP Secret Manager Detail

- **Protocol**: `gcloud secrets versions access` CLI
- **Base URL / SDK**: GCP project-specific secrets (`mis_certificate`, `mis_certificate_chain`, `mis_private_key` and variants per project)
- **Auth**: GCP service account
- **Purpose**: Retrieves TLS certificates at Dataproc cluster initialization time for Kafka mTLS and MDS API mTLS; generates JKS keystore and truststore files
- **Failure mode**: Initialization script exits with code 2 for unexpected project ID; cluster creation fails if certs unavailable

### Artifactory Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `https://artifactory.groupondev.com/artifactory/releases/`
- **Auth**: No auth configured in job configs (internal Artifactory)
- **Purpose**: Downloads Spark assembly JARs for all pipeline jobs (mds-janus, mds-backfill, deals-cluster, deal-performance, deal-attribute) at job submission
- **Failure mode**: Job submission fails if Artifactory unreachable; no retry at the DAG level for this step

### Tableau Refresh API Detail

- **Protocol**: HTTP
- **Base URL / SDK**: `http://<REFRESH_API_VIP>/ExtractAPI/extractData?id=<EXTRACT_ID>&user=<SERVICE_USER>`
- **Auth**: `user` query parameter (service account)
- **Purpose**: Triggers Tableau extract refresh after Tableau Hive tables are updated by the archival tableau workflow
- **Failure mode**: `curl -s` call; failure is silent (no error handling in `run.sh`)
- **Circuit breaker**: None detected

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Marketing Deal Service (MDS API) | HTTPS/JSON (mTLS) | Fetches full deal snapshots per country/brand for archival | `continuumMarketingDealService` |
| Kafka / Message Bus (Janus tier-2) | Kafka (MSK, mTLS) | Consumes Janus tier-2 streaming events containing deal IDs | `messageBus` |
| Enterprise Data Warehouse (Hive/EDW) | Hive SQL (via Dataproc) | Reads active deals and deal performance data; writes archival and analytics partitions | `edw` |

### Marketing Deal Service Detail

- **Protocol**: HTTPS/JSON with mTLS certificate authentication
- **Base URL / SDK**: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` with `Host: marketing-deal-service.production.service`
- **Auth**: Mutual TLS — certificates from GCP Secret Manager, placed at `/var/groupon/cert_with_chain.cert` and `/var/groupon/private_key.pem`; client ID `mds_client: mds_archive`
- **Purpose**: Downloads complete deal snapshots for each country/brand combination as newline-delimited JSON; used by archival processor (`get_mds_data` task)
- **Failure mode**: Shell script retries up to `max_http_attempts: 3`; exits on HTTP 503 or non-zero curl status

### Kafka / Message Bus Detail

- **Protocol**: Kafka (MSK) with TLS/mTLS using JKS keystore
- **Consumer group**: `mds_janus_msk_prod_3`
- **Purpose**: Janus Spark Streaming job consumes tier-2 topic events containing deal IDs and pushes them to Redis queue
- **Auth**: TLS keystore `mis-keystore.jks` generated at cluster init from GCP Secret Manager certs; truststore at `/var/groupon/truststore.jks`

## Consumed By

> Upstream consumers are tracked in the central architecture model. This service has no inbound callers — all pipelines are internally scheduled.

## Dependency Health

- MDS API calls use shell-level retry (up to 3 attempts) with exit on persistent failure; errors trigger email alerts via `mds-dev@groupon.com` and SMTP handler in Zombie Runner logging config
- Archival data quality checks emit alerts via email to `mds-alerts@groupondev.opsgenie.net` and cc `mis-engineering@groupon.com` when deal count day-over-day change exceeds ±5% threshold
- Dataproc cluster failures surface in Airflow DAG task logs and are forwarded to Stackdriver Logging (`loggingStack`)
- Jenkins pipeline failures notify Slack channel `mis-deployment` with `anyFail` notification and ping the commit author
