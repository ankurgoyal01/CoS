---
service: "mds-feed-api"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 7
internal_count: 2
---

# Integrations

## Overview

The Marketing Feed Service integrates with seven external systems and two internal Groupon systems. External integrations cover Spark job orchestration (Apache Livy on GCP Dataproc), cloud storage (GCS), data warehousing (BigQuery/GCS read path for feed data), AWS S3 for upload destinations, SFTP/FTP for partner uploads, and the Groupon Message Bus for event publishing. Internal integrations include the companion Spark job (`mds-feed-job`) and the Groupon DaaS PostgreSQL platform.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Apache Livy (GCP Dataproc) | REST (Retrofit HTTP) | Submit and monitor Apache Spark feed generation jobs | yes | `continuumMdsFeedApi` |
| Google Cloud Storage (GCS) | GCS SDK | Read generated feed file artifacts and provide dispatch URLs | yes | `bigQuery` |
| BigQuery / GCS Analytics | GCS/BigQuery APIs | Feed data source path (deal data read by the Spark job from GCS paths) | yes | `bigQuery` |
| AWS S3 | AWS SDK (aws-java-sdk-s3) | Upload generated feed files to S3 destinations | no | `continuumMdsFeedApi` |
| SFTP / SSH partners | JSch (SSH/SFTP) | Upload generated feeds to marketing partner SFTP endpoints | no | `continuumMdsFeedApi` |
| FTP partners | Apache Commons Net | Upload generated feeds to marketing partner FTP endpoints | no | `continuumMdsFeedApi` |
| Groupon Message Bus (Mbus) | JMS (jtier-messagebus-client) | Publish `GeneratedFeedDto` events when feed generation completes | no | `messageBus` |

### Apache Livy (GCP Dataproc) Detail

- **Protocol**: REST via Retrofit HTTP client (`livyServiceGCPClient` configuration)
- **Base URL / SDK**: `jtier-retrofit` + `FSLivyClient`; Livy deployed on `dataproc-cluster-mds-feeds` GCP Dataproc cluster, port `8998`
- **Auth**: GCP service account (managed at cluster level)
- **Purpose**: Submits Apache Spark batch jobs for feed file generation; monitors batch state (`running`, `success`, `dead`)
- **Failure mode**: Spark job submissions fail; `CheckBatchStateJob` detects `dead` state and triggers Wavefront/OpsGenie alert
- **Circuit breaker**: No evidence found in codebase

### Google Cloud Storage (GCS) Detail

- **Protocol**: GCS Java SDK (`google-cloud-storage` 1.111.2)
- **Base URL / SDK**: `StorageOptions` with GCP project ID and service account credentials from `googleCloud` config
- **Auth**: GCP service account credentials (PKCS8 private key via `GoogleCloudConfig`)
- **Purpose**: Reads generated feed file artifacts from GCS buckets; provides temporary download URLs via `DispatchService`; GCS paths follow pattern `gs://grpn-dnd-prod-analytics-grp-mars-mds/...`
- **Failure mode**: Dispatch URLs cannot be generated; upload operations using GCP as destination also fail
- **Circuit breaker**: No evidence found in codebase

### AWS S3 Detail

- **Protocol**: AWS Java SDK (`aws-java-sdk-s3` 1.12.248, `aws-java-sdk-sts` 1.12.276)
- **Base URL / SDK**: `AWSClient` + `S3FeedUploader`
- **Auth**: AWS credentials from `{JTIER_USER_HOME}/.aws/credentials` on each pod
- **Purpose**: Uploads generated feed files to configured S3 bucket destinations
- **Failure mode**: Upload batch transitions to failed state; alerts via PagerDuty
- **Circuit breaker**: No evidence found in codebase

### SFTP / SSH Partners Detail

- **Protocol**: SSH/SFTP via JSch (`jsch` 0.1.55)
- **Base URL / SDK**: `SFTPFeedUploader`; known partner IPs managed via Kubernetes NetworkPolicy (`network-policy-production-sftp.yml`)
- **Auth**: SSH key pairs stored encrypted in PostgreSQL; passphrases managed in upload profiles
- **Purpose**: Pushes generated feed files to external marketing partner SFTP servers (e.g., Feedonomics, Criteo, Rakuten, Linksynergy, Databreakers, Dotidot)
- **Failure mode**: Upload batch transitions to failed state; operator must re-trigger via `/upload/{feedUUID}`
- **Circuit breaker**: resilience4j-retry provides retry logic

### Groupon Message Bus (Mbus) Detail

- **Protocol**: JMS topic (`jtier-messagebus-client`)
- **Base URL / SDK**: Mbus destination `mds-feed-publishing` (configured in `mbus` config block)
- **Auth**: Mbus username/password (configured via secrets)
- **Purpose**: Publishes `GeneratedFeedDto` events when a feed batch successfully completes, enabling downstream systems to react to new feed availability
- **Failure mode**: `MbusPublishingException` is thrown; feed generation result is still stored in database
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| DaaS PostgreSQL (mktg_feed_service) | JDBC/pgbouncer | Transactional feed metadata storage | `continuumMdsFeedApiPostgres` |
| mds-feed-job (Spark job) | REST callback to `/metrics` | Posts feed generation metrics back after generation; reads feed config during job execution | `continuumMdsFeedApi` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include:
>
> - Operations teams and affiliate managers via the REST API (CRUD on feed configurations)
> - `mds-feed-job` Spark job (reads feed config via REST; posts metrics back via `/metrics`)
> - Downstream marketing systems subscribing to `mds-feed-publishing` Mbus topic

## Dependency Health

- **Livy**: Checked hourly by the `CheckBatchStateJob` Quartz cron via `/metrics/ping` endpoint; dead batches trigger Wavefront/OpsGenie alerts
- **PostgreSQL**: Managed by GDS team; DaaS pgbouncer on port 5432 provides connection pooling; contact `#gds-daas` for issues
- **GCS/S3**: Credentials must be present on pods; S3 credentials at `{JTIER_USER_HOME}/.aws/credentials`
- **Mbus**: Connection managed by `MbusWriter` lifecycle; publishing failures throw `MbusPublishingException`
