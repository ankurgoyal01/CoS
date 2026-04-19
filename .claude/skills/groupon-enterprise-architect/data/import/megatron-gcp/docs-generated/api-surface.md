---
service: "megatron-gcp"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

Megatron GCP does not expose an HTTP, gRPC, or GraphQL API. It is a scheduled batch service: Airflow DAGs are the sole control interface. Pipelines are triggered by Airflow's scheduler on cron expressions defined in YAML config files, or manually via the Airflow UI with optional `force`, `num_workers`, `master_machine_type`, and `worker_machine_type` runtime parameters passed as `dag_run.conf`.

## Endpoints

> No evidence found in codebase.

This service does not expose HTTP endpoints. Operational interaction occurs through the Apache Airflow Web UI hosted on Cloud Composer.

## Request/Response Patterns

### Common headers

> Not applicable — no HTTP surface.

### Error format

> Not applicable — no HTTP surface.

### Pagination

> Not applicable — no HTTP surface.

## Rate Limits

> No rate limiting configured. Pipeline concurrency is controlled by Airflow DAG-level settings (`concurrency`, `max_active_runs`) defined per service in the YAML factory configs.

| Airflow Control | MySQL Config | Postgres Config |
|----------------|-------------|----------------|
| Default DAG concurrency | `DEFAULT_CONCURRENCY: 2` | `DEFAULT_CONCURRENCY: 2` |
| Audit DAG concurrency | `AUDIT_CONCURRENCY: 4` | `AUDIT_CONCURRENCY: 4` |
| Max active runs per DAG | `MAX_ACTIVE_RUNS: 1` | `MAX_ACTIVE_RUNS: 1` |
| Default sqoop concurrency | `DEFAULT_SQOOP_CONCURRENCY: 1` | `DEFAULT_SQOOP_CONCURRENCY: 2` |
| DAG run timeout | 18 hours | 18 hours |

## Versioning

> No evidence found in codebase. Pipeline artifact version is declared as a constant (`PIPELINE_ARTIFACT_VERSION = 'v0.0.1'`) inside generated DAG code, but no API versioning strategy applies.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema exist in this repository.
