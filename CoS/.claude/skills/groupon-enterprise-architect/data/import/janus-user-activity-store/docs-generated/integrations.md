---
service: "janus-user-activity-store"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 2
---

# Integrations

## Overview

Janus User Activity Store integrates with four external GCP-managed systems (Bigtable, GCS Parquet source, Dataproc, Cloud Composer/Airflow) and two internal Groupon platform services (the edge proxy / hybrid boundary and the metrics/logging stacks). All integrations are outbound — this service has no inbound callers.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Cloud Bigtable | HBase API / gRPC | Primary write target for user activity records | yes | `bigtableRealtimeStore` |
| GCS (Janus canonical Parquet bucket) | GCS SDK (Hadoop FileSystem) | Read-only input of hourly Janus canonical event Parquet partitions | yes | stub-only |
| Google Cloud Dataproc | Dataproc REST API (Airflow operator) | Ephemeral Spark cluster creation and Spark job submission | yes | stub-only |
| Janus Metadata API (`/janus/api/v1/destination`) | HTTPS / mTLS | Resolves JUNO event destination metadata used by `InMemoryJanusMetaStoreClient` | no (in-memory fallback via hardcoded event maps) | stub-only |

### Google Cloud Bigtable Detail

- **Protocol**: HBase API over gRPC, via `bigtable-hbase-2.x-hadoop` 1.26.3
- **SDK**: `com.google.cloud.bigtable:bigtable-hbase-2.x-hadoop:1.26.3`
- **Auth**: GCP service account (`sa-dataproc-nodes@prj-grp-janus-prod-0808.iam.gserviceaccount.com`) via `GOOGLE_APPLICATION_CREDENTIALS` / Workload Identity on Dataproc nodes
- **Purpose**: Stores translated user activity records in per-platform monthly tables keyed by `consumerId`
- **Failure mode**: Spark partition fails; Airflow task marked failed; PagerDuty alert triggered via `janus-prod-alerts@groupon.pagerduty.com`
- **Circuit breaker**: No explicit circuit breaker; `insertRecords` uses HBase batch `table.put()` with `try/finally` for connection cleanup

### GCS Janus Canonical Parquet Bucket Detail

- **Protocol**: GCS via Hadoop FileSystem / Spark native Parquet reader
- **SDK**: Spark built-in `spark.read.parquet()` using GCS Hadoop connector
- **Auth**: Dataproc node service account
- **Purpose**: Reads hourly Janus event partitions: `gs://grpn-dnd-prod-pipelines-yati-canonicals/kafka/region=na/source=janus-all/ds={date}/hour={hour}/`
- **Failure mode**: Spark job fails if the Parquet path is missing or unreadable; Airflow task retries are disabled (`retries: 0`), surfacing immediately
- **Circuit breaker**: No circuit breaker; Parquet read is a single Spark action

### Janus Metadata API Detail

- **Protocol**: HTTPS with mTLS (mutual TLS via custom `SSLContext`)
- **Base URL**: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com/janus/api/v1/destination` (production)
- **Auth**: Mutual TLS using keystore at `/var/groupon/janus-yati-keystore.jks` and truststore at `/var/groupon/truststore.jks`. `Host` header set to `janus-web-cloud.production.service`.
- **Purpose**: Fetches JUNO destination mapping for events; used by `InMemoryJanusMetaStoreClient.junoEventDestinations()`
- **Failure mode**: `ApiCallException` thrown; since the `InMemoryJanusMetaStoreClient` uses hardcoded in-memory event attribute maps for filtering and translation, the destination API call is supplementary; job can proceed without it for core filtering logic
- **Circuit breaker**: Retry handler: up to 5 retries on `IOException`; service unavailability retry: up to 5 retries on HTTP 5xx with exponential backoff (initial 5s, max 60s)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Edge Proxy / Hybrid Boundary | HTTPS / mTLS | Routes requests from Dataproc nodes (GCP network) to internal Janus API service | `apiProxy` |
| Metrics Stack (Telegraf/Wavefront) | Telegraf Influx line protocol (HTTP) | Receives gauge metrics: `input_record_count`, `partition_time`, `input_record_bytes`, per-table `_record_count`, `_time`, `_bytes`, `runner_time` | `metricsStack` |
| Logging Stack (Stackdriver) | Cloud Logging (Stackdriver) | Receives structured batch execution and error logs from Dataproc job driver and executors | `loggingStack` |

## Consumed By

> Not applicable. This service writes data to Bigtable. Upstream consumers of that Bigtable data are not tracked in this repository.

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- **Bigtable**: Connection established once per Spark executor JVM via `BigTableConnectionPool`; connection reused across partitions scheduled on the same executor. Shutdown hook closes connection on JVM exit.
- **Janus API**: OkHttp client with 5-retry exponential backoff for HTTP 5xx responses (5s initial, 60s max wait) and up to 5 retries on `IOException`. Connection closed after each `junoEventDestinations()` call.
- **GCS**: No explicit retry configured beyond Hadoop GCS connector defaults; Spark job failure propagates to Airflow for alerting.
