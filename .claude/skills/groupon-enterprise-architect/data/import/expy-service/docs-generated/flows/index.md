---
service: "expy-service"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Expy Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Experiment Bucketing Decision](experiment-bucketing-decision.md) | synchronous | API call — POST `/experiments` | Receives a bucketing request, evaluates experiment config from cache/datafile, and returns a variation decision via the Optimizely SDK |
| [Datafile Update Scheduled Job](datafile-update-scheduled-job.md) | scheduled | Quartz job — periodic schedule | Fetches the latest Optimizely datafile from CDN and/or Data Listener, validates it, updates MySQL, and refreshes the in-memory cache |
| [S3 Backup Copy Daily](s3-backup-copy-daily.md) | scheduled | Quartz job — daily schedule | Copies Optimizely datafiles from the Optimizely-owned S3 bucket to the Groupon-owned S3 bucket as a daily backup |
| [Datafile Parsing Error Logging](datafile-parsing-error-logging.md) | event-driven | Internal — triggered on datafile parse failure during refresh | Catches datafile parse failures during scheduled refresh, logs error details to MySQL for audit and observability |
| [Feature Flag CRUD](feature-flag-crud.md) | synchronous | API call — POST/PUT/DELETE `/feature-manager/*` | Accepts a feature flag create/update/delete request, applies changes via the service layer, persists to MySQL, and optionally syncs to the Optimizely API |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **Experiment Bucketing Decision** flow touches the `continuumExpyService` and the Optimizely SDK (embedded library) — no dynamic view is currently defined in the architecture model.
- The **S3 Backup Copy Daily** flow spans `continuumExpyService`, `optimizelyS3Bucket_84a1`, and `grouponS3Bucket_7c3d`.
- The **Datafile Update Scheduled Job** flow spans `continuumExpyService`, `optimizelyCdnSystem_9d42`, `optimizelyDataListenerSystem_5b7f`, and `continuumExpyMySql`.

> No dynamic views are currently defined in the Structurizr architecture model for this service. Refer to the component view `components-continuumExpyService` (view key: `ExpyServiceComponents`) for structural context.
