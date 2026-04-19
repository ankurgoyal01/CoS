---
service: "AudienceCalculationSpark"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 4
---

# Integrations

## Overview

AudienceCalculationSpark has two categories of integration: outbound HTTP calls to `continuumAudienceManagementService` (AMS) for job lifecycle reporting, and data-layer integrations with Hive, HDFS, Cassandra, and GCP Bigtable. It is never called by external systems directly — all invocations originate from AMS via `spark-submit`. Retry logic is applied to HTTP calls using the internal `AudienceUtil.retry` helper.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Bigtable | Bigtable API / gRPC | Writes realtime PA membership payloads (NA only) | No (skipped for EMEA and Universal type) | `bigtableRealtimeStore` |
| Groupon Nexus Artifactory | HTTPS / Maven | Resolves Groupon internal dependencies at build time | Yes (build only) | Not in C4 model |

### GCP Bigtable Detail

- **Protocol**: gRPC (via `grpc-netty-shaded 1.55.0`)
- **Base URL / SDK**: `com.groupon.crm:bigtable_client:0.3.2-SNAPSHOT` — loaded via `BigtableHandler.get(env, table, columnFamily)`
- **Auth**: GCP Service Account credentials loaded from GCS bucket (`grpn-dnd-prod-analytics-grp-audience`)
- **Purpose**: Writes realtime audience membership records keyed by `consumer_id` or `bcookie` into `user_data_main` or `bcookie_data_main` tables
- **Failure mode**: Exception thrown; PA job reports FAILED status to AMS
- **Circuit breaker**: No — no circuit breaker pattern observed

---

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| AudienceManagementService (AMS) | HTTPS / JSON | Receives workflow spark inputs; receives all job lifecycle callbacks (IN_PROGRESS, SUCCESSFUL, FAILED) | `continuumAudienceManagementService` |
| Hive Warehouse (CerebroV2) | Hive SQL (JDBC/Thrift) | Reads/writes SA, CA, and PA audience tables | `hiveWarehouse` |
| HDFS (CerebroV2) | HDFS API | Reads source CSV files; writes PA CSV, feedback CSV, deal-bucket JSON | `hdfsStorage` |
| Cassandra Audience Store | Cassandra (spark-cassandra-connector) | Writes PA payload membership records | `cassandraAudienceStore` |

### AudienceManagementService (AMS) Detail

- **Protocol**: HTTPS/JSON — HTTP PUT (lifecycle updates) and HTTP POST (result reporting)
- **Base URL**: Environment-specific VIP, e.g.:
  - NA Production: `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com`
  - NA Staging: `https://edge-proxy--staging--default.stable.us-central1.gcp.groupondev.com`
  - NA UAT: `http://audience-app1-uat.snc1:9000`
  - EMEA Production: `https://edge-proxy--production--default.prod.eu-west-1.aws.groupondev.com`
- **Auth**: Cloud Conveyer mutual TLS (`AudienceSSLConfiguration` / `CloudConveyerApplication.getSSLSocketFactory`); `Host` header set to `ams.production.service` or `ams.staging.service`
- **Endpoints called** (outbound):
  - `PUT /<host>/updateSourcedAudienceInProgress/<id>` — marks SA as IN_PROGRESS
  - `PUT /<host>/updatePublishedAudienceInProgress/<id>` — marks PA as IN_PROGRESS
  - `PUT /<host>/updateCalculatedAudienceInProgress/<id>` — marks CA as IN_PROGRESS
  - `POST /<host>/updateImportResults` — reports SA final result
  - `POST /<host>/updatePublicationResults` — reports PA final result
  - `POST /<host>/updateCalculationResults` — reports CA final result
  - `PUT /<host>/published-audience/<id>/csv-status` — updates CSV generation status
  - `GET /<host>/published-audience/<id>/spark-input` — fetches PA spark input (batch flow)
  - `GET /<host>/getPublishedAudience/<id>` — fetches PA details
  - `GET /<host>/getSourcedAudience/1` — fetches system SA table info
- **Failure mode**: Job logs error and exits (`sys.exit(1)`) if IN_PROGRESS update fails; result failures are reported to AMS before termination
- **Circuit breaker**: No — `retry()` helper with interval-based retry is used instead

---

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| AudienceManagementService (AMS) | spark-submit / YARN | Triggers all Spark jobs via `spark-submit`; passes workflow JSON as command-line argument |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- Outbound AMS HTTP calls use `AudienceUtil.retry()` — retries with configurable interval (default 5 min for SA flows)
- Bigtable writes use exception-based failure with immediate error propagation; no retry wrapper observed for Bigtable
- Spark DataFrame operations use `Try`/`Success`/`Failure` for error containment; failures cascade to AMS result reporting
- HDFS field validation runs before SA execution to catch CSV format errors early
