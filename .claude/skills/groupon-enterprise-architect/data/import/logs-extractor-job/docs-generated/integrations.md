---
service: "logs-extractor-job"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 1
---

# Integrations

## Overview

The Log Extractor Job has three integration dependencies: one internal Groupon SDK (`@groupon/logs-processor`) that abstracts Elasticsearch access, one external Google Cloud service (BigQuery), and one optional external relational database (MySQL). All communication is outbound — no service calls into this job.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google BigQuery | BigQuery API (gRPC/HTTPS via SDK) | Primary analytical data sink; receives all transformed log tables | yes | `continuumLogExtractorBigQuery` |
| MySQL | MySQL protocol (TCP) | Optional relational data sink for operational queries | no | `continuumLogExtractorMySQL` |
| Elasticsearch | HTTPS, Elasticsearch REST API | Source of raw log documents for all log types | yes | `continuumLogExtractorElasticsearch` |

### Google BigQuery Detail

- **Protocol**: BigQuery Storage API via `@google-cloud/bigquery` v7.5.2
- **Base URL / SDK**: `@google-cloud/bigquery` npm package; project configured by `BQ_PROJECT_ID` env var
- **Auth**: Google Cloud service account key file; path configured by `BQ_KEY_FILE` env var (mounted as a Kubernetes Secret)
- **Purpose**: Receives transformed log datasets (`pwa_logs`, `proxy_logs`, `lazlo_logs`, `orders_logs`, `bcookie_summary`, `combined_logs`) for long-term analytical storage and querying
- **Failure mode**: Job throws an error and exits with code 1; no retry logic beyond BigQuery SDK defaults; `PartialFailureError` is caught and logged without halting the batch — failed rows are counted and skipped
- **Circuit breaker**: No

### MySQL Detail

- **Protocol**: MySQL protocol via `mysql2/promise` v3.9.7 with connection pooling
- **Base URL / SDK**: Host configured by `MYSQL_HOST` env var; port by `MYSQL_PORT` (default `3306`)
- **Auth**: Username/password via `MYSQL_USER` / `MYSQL_PASSWORD` env vars
- **Purpose**: Optional secondary store for extracted logs to enable operational SQL reporting; disabled in staging and production by default (`ENABLE_MYSQL=false`)
- **Failure mode**: Job throws and rolls back the current transaction; exits with code 1
- **Circuit breaker**: No; connection pool of 10 with `waitForConnections: true`

### Elasticsearch Detail

- **Protocol**: HTTPS, Elasticsearch REST API (via `@groupon/logs-processor` SDK)
- **Base URL / SDK**: US endpoint — `https://prod-unified-es.us-central1.logging.prod.gcp.groupondev.com`; EU endpoint — `https://logging-prod-eu-unified1.grpn-logging-prod.eu-west-1.aws.groupondev.com:9200` (from `env.example`)
- **Auth**: Basic auth via `ES_USERNAME` / `ES_PASSWORD` env vars (managed by logs-processor SDK)
- **Purpose**: Source of all raw operational logs; the `extractLogsForTimeRangeExact` SDK function fetches PWA, proxy, Lazlo, and orders logs for the configured time range and region
- **Failure mode**: Job throws and exits with code 1; no retry beyond SDK internals
- **Circuit breaker**: No explicit circuit breaker; handled within logs-processor SDK

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `@groupon/logs-processor` | npm module (in-process) | Elasticsearch client initialization, log extraction, logger, and utility functions | `continuumLogExtractorJob_logsProcessorAdapter` |

### `@groupon/logs-processor` Detail

- **Source**: GitHub Enterprise — `https://github.groupondev.com/sdash/logs_processor.git#main`
- **Integration point**: Loaded via `createRequire` CommonJS adapter (`src/utils/commonjsAdapter.js`) into ESM modules
- **Exposed APIs used**:
  - `logExtraction.extractLogsForTimeRangeExact(options)` — fetches all log types from Elasticsearch
  - `logger` — structured logger used across all service components
- **Failure mode**: Missing or broken module installation causes immediate startup failure

## Consumed By

> Upstream consumers are tracked in the central architecture model. This job is scheduled by the Kubernetes CronJob infrastructure and has no known service-to-service callers.

## Dependency Health

- **Elasticsearch**: No health check before extraction; failure surfaces as an exception during `extractLogsForTimeRangeExact`
- **BigQuery**: `ensureDatasetExists()` and `ensureTableExists()` are called before any upload; table creation includes a 10-second wait for BigQuery to register the new table
- **MySQL**: `connection.ping()` is called immediately after pool creation to validate connectivity; failure aborts before any upload attempt
