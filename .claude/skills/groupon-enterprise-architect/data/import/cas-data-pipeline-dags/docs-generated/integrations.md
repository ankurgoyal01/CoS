---
service: "cas-data-pipeline-dags"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 7
internal_count: 2
---

# Integrations

## Overview

`cas-data-pipeline-dags` has 7 external GCP/infrastructure dependencies and 2 internal Groupon service dependencies. All outbound calls originate from Spark jobs running inside ephemeral Dataproc clusters. The DAG layer interacts exclusively with GCP Cloud Composer and the Dataproc control plane API. The Spark job layer reads from Hive, writes to PostgreSQL and GCS, calls the arbitration-service and AMS REST APIs, and consumes from Kafka.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Cloud Composer | GCS bucket sync | Hosts and schedules Airflow DAGs; reads DAG files from `COMPOSER_DAGS_BUCKET` | yes | `gcpCloudComposer` |
| GCP Dataproc | GCP REST API (via Airflow operators) | Creates ephemeral clusters, submits Spark jobs, deletes clusters | yes | `gcpDataprocCluster` |
| GCP Dataproc Metastore | Hive Thrift | Provides Hive metastore for Spark jobs to resolve table schemas and locations | yes | `gcpDataprocMetastore` |
| GCS (artifact bucket) | GCS URI | Stores Spark assembly JAR artifacts resolved via `artifact_base_path` config | yes | `gcpGcsBucket` |
| GCS (data bucket) | GCS API | Stores audience path CSVs, Janus-YATI output, and Spark Structured Streaming checkpoints | yes | `gcpGcsBucket` |
| Kafka (`arbitration_log`) | Kafka 0.10 / SSL | Janus-YATI DAG consumes arbitration log events via Spark Structured Streaming | no | external |
| Nexus / Artifactory | Maven / HTTP | Build-time: publishes and resolves Scala assembly JARs; `fabfile.py` uploads to `nexus-dev.snc1` | no | `artifactRepository` |

### GCP Cloud Composer Detail

- **Protocol**: GCS bucket sync; Airflow scheduler reads DAG Python files from `COMPOSER_DAGS_BUCKET`
- **Base URL / SDK**: Bucket name injected via `COMPOSER_DAGS_BUCKET` environment variable (e.g., `us-central1-grp-shared-comp-155675d0-bucket`)
- **Auth**: GCP service account attached to the Kubernetes context
- **Purpose**: Provides the managed Airflow runtime that triggers all CAS pipeline DAGs
- **Failure mode**: DAG runs are not triggered; no pipeline processing occurs
- **Circuit breaker**: No — managed GCP service

### GCP Dataproc Detail

- **Protocol**: GCP REST API via `DataprocCreateClusterOperator`, `DataprocSubmitJobOperator`, `DataprocDeleteClusterOperator` from `airflow.providers.google.cloud.operators.dataproc`
- **Base URL / SDK**: `airflow.providers.google.cloud.operators.dataproc`
- **Auth**: GCP service account (`@service_account` config variable) with `internal_ip_only: true`; clusters tagged `allow-iap-ssh`, `dataproc-vm`
- **Purpose**: Executes all Spark batch jobs on ephemeral n1-standard-8 clusters (Dataproc image `1.5-debian10`); master: 1 × n1-standard-8, workers: `@worker_num_instances` × n1-standard-8, 500 GB pd-standard boot disk each
- **Failure mode**: DAG task fails; cluster may need manual deletion if create succeeds but submit fails
- **Circuit breaker**: No — `retries=0` on all Dataproc submit operators

### Kafka (`arbitration_log`) Detail

- **Protocol**: Kafka 0.10 with SSL (`spark-sql-kafka-0-10` and `spark-streaming-kafka-0-10`)
- **Base URL / SDK**: Bootstrap servers `kafka-grpn-consumer.grpn-dse-stable.us-west-2.aws.groupondev.com:9094`
- **Auth**: TLS keystore (`cas-keystore.jks` / `push-cas-data-pipelines.jks`) injected via Dataproc cluster init action; secret name `tls--push-cas-data-pipelines`
- **Purpose**: Janus-YATI DAG (`arbitration_janus_yati.py`) reads `arbitration_log` topic via consumer group `cas_stable_arbitration_log_2`, processing up to 1,000,000 offsets per micro-batch trigger
- **Failure mode**: Janus-YATI job fails to ingest; GCS output is incomplete; downstream analytics are impacted
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| arbitration-service | HTTPS/REST | `DownloadAudiencePaths` Spark job calls `getaudienceconfigs` endpoint to retrieve audience metadata needed for audience path pipeline | `arbitrationServiceApi` |
| AMS (Audience Management Service) | HTTPS/REST | `DownloadAudiencePaths` Spark job calls scheduled/published audience endpoints to resolve `hdfsURI` paths for audience data | `amsServiceApi` |

### arbitration-service Detail

- **Protocol**: HTTPS/REST
- **Auth**: TLS client cert (`push-cas-data-pipelines.jks` keystore loaded via Dataproc init script); GCE metadata secret `tls--push-cas-data-pipelines`
- **Purpose**: Provides audience configuration objects (audience IDs, feature metadata) consumed by the audience path download pipeline
- **Failure mode**: `DownloadAudiencePaths` job fails; audience path CSV outputs are not written to GCS
- **Circuit breaker**: No evidence found in codebase

### AMS Service Detail

- **Protocol**: HTTPS/REST
- **Auth**: Same TLS keystore as arbitration-service
- **Purpose**: Resolves HDFS URI paths for published/scheduled audience segments so `DownloadAudiencePaths` can locate the audience data in GCS/HDFS
- **Failure mode**: Audience path download job fails; missing URI resolution causes incomplete pipeline output
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Pipeline outputs (PostgreSQL ranking tables, GCS audience path CSVs, Hive feature tables) are consumed by the arbitration-service and downstream ML systems. The DAG files themselves are consumed by GCP Cloud Composer.

## Dependency Health

No explicit circuit breaker or retry logic is configured at the DAG level (`retries=0` on all Dataproc submit operators). Cluster lifecycle management (create on start, delete on end) is the primary reliability pattern — a failed Spark job causes the DAG task to fail and the cluster is cleaned up by the delete step. Monitoring for dependency health is performed via the Airflow UI and Stackdriver Logging (configured via `dataproc:dataproc.logging.stackdriver.enable: "true"` in all cluster software configs).
