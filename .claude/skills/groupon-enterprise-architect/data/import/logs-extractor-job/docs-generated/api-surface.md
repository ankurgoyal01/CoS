---
service: "logs-extractor-job"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

The Log Extractor Job exposes no inbound HTTP, gRPC, or message-bus API. It is a batch job invoked via Kubernetes CronJob schedule or manually from the command line. There are no endpoints for external consumers to call.

## Endpoints

> Not applicable. This service has no inbound API surface.

## CLI Interface

The job accepts the following command-line arguments when invoked directly:

| Flag | Argument | Purpose | Example |
|------|----------|---------|---------|
| `--start_time` | UTC ISO string | Override extraction start time | `--start_time 2024-01-01T00:00:00Z` |
| `--end_time` | UTC ISO string | Override extraction end time | `--end_time 2024-01-01T01:00:00Z` |
| `--bq_dataset` | Dataset name | Override `BQ_DATASET_ID` env var | `--bq_dataset custom_logs` |
| `--mysql_database` | Database name | Override `MYSQL_DATABASE` env var | `--mysql_database custom_db` |
| `--help`, `-h` | — | Print usage help and exit | `--help` |

**Validation rules:**
- `--start_time` and `--end_time` must both be provided together; providing only one throws an error.
- `--bq_dataset`: must match `/^[a-zA-Z_][a-zA-Z0-9_]*$/`, max 1024 characters.
- `--mysql_database`: must match `/^[a-zA-Z_][a-zA-Z0-9_-]*$/`, max 64 characters.
- `start_time` must be strictly before `end_time`.

## Request/Response Patterns

> Not applicable. No inbound request/response surface.

## Rate Limits

> Not applicable. No inbound API surface; no rate limiting configured.

## Versioning

> Not applicable. No API versioning — CLI flags are the only interface.

## OpenAPI / Schema References

> No evidence found in codebase.
