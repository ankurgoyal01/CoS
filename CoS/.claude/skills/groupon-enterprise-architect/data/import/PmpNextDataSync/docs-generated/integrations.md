---
service: "PmpNextDataSync"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 2
---

# Integrations

## Overview

PmpNextDataSync integrates with five external systems and two internal Continuum services. The dominant pattern is outbound: the Spark processor reads from PostgreSQL databases and writes to GCS. Configuration is fetched from GitHub Enterprise at job start. Credentials are loaded from a secrets file resolved by the Secret Manager component. Airflow DAGs download JARs from Artifactory to supply to Dataproc clusters. There is no inbound integration pattern — no external system calls into this service.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GitHub Enterprise API | HTTPS (GitHub REST v3) | Fetch flow YAML config files at job startup | yes | `externalGitHubApi` |
| PostgreSQL operational databases | JDBC | Read source tables for sync | yes | `externalPostgresOperationalDatabases` |
| Google Dataproc | GCP API (Airflow operator) | Provision ephemeral Spark clusters; submit Spark jobs | yes | `externalDataprocService` |
| Google Cloud Storage | GCS native (Hadoop connector) | Store Hudi bronze tables and checkpoint state | yes | `externalGoogleCloudStorage` |
| Artifactory | HTTPS | Distribute compiled Spark JAR artifacts to Dataproc | yes | `artifactory` |

### GitHub Enterprise API Detail

- **Protocol**: HTTPS, GitHub REST API v3
- **Base URL**: `https://api.github.groupondev.com/repos/Push/PmpNextDataSync`
- **Auth**: Bearer token (`git_token` from `ApplicationConfig`), `X-GitHub-Api-Version: 2022-11-28`
- **Purpose**: Fetches flow YAML config files from `DataSyncConfig/<folder_path>/<flow_name>.yaml` on the `main` branch at Spark job startup. This allows config changes without redeployment of the JAR.
- **Failure mode**: Retries with exponential backoff (up to 5 attempts, starting at 1 ms delay). Job fails hard if all retries exhausted.
- **Circuit breaker**: No — manual retry only.

### PostgreSQL Operational Databases Detail

- **Protocol**: JDBC (PostgreSQL wire protocol, port 5432)
- **Auth**: Username/password per database, stored in `secrets.json` and keyed by `gcp_secret_credentials_key`.
- **Purpose**: Source of campaign, subscription, arbitration, and push token data for bronze layer ingestion.
- **Failure mode**: Spark job fails; Airflow retries the task up to 2 times with zero delay. Checkpoint is not committed on failure, so subsequent runs re-attempt from the last successful watermark.
- **Circuit breaker**: No.

### Google Dataproc Detail

- **Protocol**: GCP Dataproc API via `DataprocCreateClusterOperator` / `DataprocSubmitJobOperator` / `DataprocDeleteClusterOperator` (Airflow providers).
- **Auth**: GCP service account (`loc-sa-csmr-aud-svc-dataproc@prj-grp-mktg-eng-prod-e034.iam.gserviceaccount.com`).
- **Purpose**: Ephemeral Spark cluster provisioned per DAG run; cluster is always deleted at DAG completion (using `TriggerRule.ALL_DONE` to ensure cleanup on failure too).
- **Failure mode**: Cluster deletion still runs on task failure.
- **Circuit breaker**: No.

### Google Cloud Storage Detail

- **Protocol**: Hadoop GCS connector (`hadoop3-2.2.14`), GCS URI scheme `gs://`.
- **Auth**: GCP service account via Hadoop configuration (`fs.gs.impl`).
- **Purpose**: Persistent storage for Hudi tables and checkpoint state. Also hosts init scripts and log4j configs for Dataproc clusters.
- **Failure mode**: Spark write fails; Hudi MERGE_ON_READ ensures partial writes do not corrupt committed state.
- **Circuit breaker**: No.

### Artifactory Detail

- **Protocol**: HTTPS
- **Base URL**: `https://artifactory.groupondev.com/artifactory/snapshots/`
- **Auth**: Maven credential resolution via `~/.ivy2/.credentials`.
- **Purpose**: Hosts compiled Spark JARs (`datasynccore_2.12`, `transformer_2.12`, `processor_2.12`, `dispatcher_na_2.12`). JARs are referenced in Dataproc job configs as `jar_file_uris`.
- **Failure mode**: Dataproc cluster creation fails if JARs cannot be retrieved.
- **Circuit breaker**: No.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Secret Manager (Continuum) | File / in-process | Loads JDBC database credentials from secrets payload | `continuumSecretManager` |
| PMP Hudi Bronze Lake | GCS write (Hudi) | Target data store for all synced tables and checkpoint records | `continuumPmpHudiBronzeLake` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Downstream Spark jobs in the medallion pipeline consume the Hudi bronze tables written by this service:
- Silver transformer JARs (e.g., `GSSTransformationJobNA`, `EmailCampaignTransformerNA`, `PushSubscriptionsTransformationJobNA`, `AudienceTransformationEmailNA`).
- Gold processor JARs (e.g., `NAEmailArbitrationProcessor`, `NAPushArbitrationProcessor`, `NAEmailCampaignProcessor`, `NAPushCampaignProcessor`).
- Dispatcher jobs (`EmailDispatcherJobNA`, `EmailDispatcherJobEMEA`).

## Dependency Health

- Airflow tasks retry up to 2 times on failure with zero delay.
- Email failure alerts are sent to `cadence-arbitration@groupondev.opsgenie.net` on task failure and retry.
- GitHub config fetches use exponential backoff (5 retries, doubling from 1 ms).
- Dataproc cluster deletion uses `TriggerRule.ALL_DONE` to guarantee cleanup even on partial job failure.
- No circuit breakers are configured; all dependencies are treated as essential for job completion.
