---
service: "janus-muncher"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 6
internal_count: 1
---

# Integrations

## Overview

Janus Muncher integrates with six external platform services: GCS (data I/O via Hadoop FileSystem API), the Janus Metadata API (schema and destination resolution), the Ultron State API (watermark and job state), Hive Metastore (partition metadata), an SMTP relay (operational alerts), and the SMA/Telegraf metrics gateway. Internally, the Orchestrator container calls the Service container via Google Cloud Dataproc job submission. All outbound HTTP connections to internal services go through the `edge-proxy` hybrid boundary in production.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCS (HDFS-compatible) | GCS / Hadoop FileSystem API | Primary input and output storage for all Parquet event files | yes | `hdfsStorage` |
| Janus Metadata API | HTTP (via edge-proxy) | Fetch event schema, destination attributes, and routing metadata | yes | stub (not in central model) |
| Ultron State API | HTTP (via edge-proxy) | Read and write job watermarks and run state | yes | stub (not in central model) |
| Hive Metastore (HiveServer2) | JDBC over HTTPS | Add and repair Hive table partitions after each write | yes | `hiveWarehouse` |
| SMTP Relay | SMTP | Send operational alert emails for dedup exclusions, backfill triggers, and task failures | no | `smtpRelay` |
| SMA / Telegraf Metrics Gateway | HTTP (InfluxDB line protocol) | Publish job-health, throughput, and lag metrics | no | `metricsStack` |

### GCS (Hadoop FileSystem API) Detail

- **Protocol**: GCS accessed via Hadoop FileSystem API (configured as default FS on Dataproc)
- **Base URL / SDK**: `core:fs.defaultFS = gs://grpn-dnd-prod-pipelines-yati-canonicals` (set in Dataproc software config)
- **Auth**: Dataproc service account `sa-dataproc-nodes@prj-grp-janus-prod-0808.iam.gserviceaccount.com` with `cloud-platform` scope
- **Purpose**: Read canonical Janus event Parquet files from Yati output; write deduplicated Janus All and Juno Hourly Parquet outputs; manage staging and trash paths
- **Failure mode**: Spark job fails; Airflow DAG marks task as failed; backfill DAG triggers if lag is detected
- **Circuit breaker**: No — relies on Spark retry logic and Airflow DAG retries (configured as 0 retries at task level)

### Janus Metadata API Detail

- **Protocol**: HTTP via edge-proxy hybrid boundary
- **Base URL / SDK**: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` → service `janus-web-cloud.production.service`, base path `/janus/api/v1`
- **Auth**: mTLS via keystore (`/var/groupon/janus-yati-keystore.jks`) and truststore (`/var/groupon/truststore.jks`) mounted on Dataproc nodes
- **Purpose**: Fetch Janus event destination metadata and schema attributes used by the Transformation Pipeline to route events to Janus All vs Juno output paths
- **Failure mode**: Spark job fails to initialise `JanusMetadataService`; DAG task fails; PagerDuty alert
- **Circuit breaker**: No explicit circuit breaker; OkHttp client (`okhttp 3.14.9`) with default timeouts

### Ultron State API Detail

- **Protocol**: HTTP via edge-proxy hybrid boundary
- **Base URL / SDK**: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` → service `ultron-api.production.service`
- **Auth**: mTLS via keystore/truststore on Dataproc nodes
- **Purpose**: Load previous watermark state to determine which hourly input windows to process; persist new high-watermark after successful job run; track job state for watchdog and lag-monitor DAGs
- **Failure mode**: Watermark cannot be loaded; job defaults or fails; watchdog DAG detects stale Ultron entries
- **Circuit breaker**: No; `ultron-client 1.26` with configurable retry settings

### Hive Metastore (HiveServer2) Detail

- **Protocol**: JDBC over HTTPS (`transportMode=http`) via `analytics.data-comp.prod.gcp.groupondev.com:8443`
- **Base URL / SDK**: `jdbc:hive2://analytics.data-comp.prod.gcp.groupondev.com:8443/default;ssl=true;transportMode=http;httpPath=gateway/pipelines-adhoc-query/hive`
- **Auth**: Username `svc_gcp_janus`; password retrieved from GCP Secret Manager (`janus-hive-credentials` secret, key `janus_non_sox_hive_password`)
- **Purpose**: Add and repair Hive partitions for `grp_gdoop_pde.janus_all` and `grp_gdoop_pde.junoHourly` after each Spark write
- **Failure mode**: Partition creation fails; Hive table may be missing new partitions; downstream queries on those partitions return empty results until manual repair
- **Circuit breaker**: No; JDBC connection with two configured server URLs for failover

### SMTP Relay Detail

- **Protocol**: SMTP
- **Base URL / SDK**: `smtp-uswest2.groupondev.com` (production); `smtp-us.groupondev.com` (orchestrator-level)
- **Auth**: No authentication configured
- **Purpose**: Send operational alert emails for: (1) dedup excluded-event alerts (`platform-data-eng@groupon.com`); (2) backfill-triggered notifications; (3) Airflow task failure callbacks
- **Failure mode**: Alert email not delivered; operational impact is limited (metrics still flow to Wavefront/PagerDuty)
- **Circuit breaker**: No

### SMA / Telegraf Metrics Gateway Detail

- **Protocol**: HTTP (InfluxDB line protocol via SMA library)
- **Base URL / SDK**: `http://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` with host header `telegraf.production.service`; metric source tag `janus-muncher`
- **Auth**: None (internal network)
- **Purpose**: Publish gauge and counter metrics for job running duration, corrupt record quantity, lag, and backfill-triggered counts; consumed by Wavefront dashboard `janus-muncher--sma`
- **Failure mode**: Metrics stop appearing on dashboard; pipeline continues to function but observability is degraded
- **Circuit breaker**: Async `overflow_pool_buffering` strategy in SMA library prevents blocking on metric send failures

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Google Cloud Dataproc | Dataproc API (Airflow provider) | Orchestrator creates ephemeral clusters and submits Spark jobs to run the Service | `continuumJanusMuncherOrchestrator` → `continuumJanusMuncherService` |
| Google Cloud Composer (Airflow) | Airflow REST API | Watchdog DAG queries Airflow API (`/api/v1/dags/.../dagRuns`) to detect incomplete muncher DAG runs | `continuumJanusMuncherOrchestrator` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Downstream GCS consumers (analytics/EDW) read from the `janus/` and `juno/junoHourly/` output GCS paths and query via `grp_gdoop_pde.janus_all` and `grp_gdoop_pde.junoHourly` Hive tables.

## Dependency Health

- **Ultron State API**: Checked by `muncher-ultron_watch_dog` DAG (every 20 minutes); detects failed/stale Ultron job instances; submits a `WatchDog` Spark class to clean up orphaned state
- **GCS**: Checked implicitly by Spark job success/failure; lag detected by `muncher-lag-monitor` DAG (every 20 minutes) via `LagMonitor` Spark class
- **Hive**: Checked by `muncher-hive-partition-creator` DAG task success/failure; no separate health probe
- **Retries**: Dataproc cluster creation configured with `create_cluster_retries = 3`; Spark tasks have Spark-native retry semantics; Airflow task-level retries set to 0 (single attempt per DAG run)
