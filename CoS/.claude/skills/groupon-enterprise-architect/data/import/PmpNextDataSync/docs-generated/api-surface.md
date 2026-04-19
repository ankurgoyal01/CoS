---
service: "PmpNextDataSync"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

PmpNextDataSync does not expose any HTTP, gRPC, or other network API surface. It is a batch Spark application invoked via Dataproc job submission by Airflow DAGs. All inputs are passed as command-line arguments (folder path, flow name, local mode flag); all outputs are written to GCS Hudi tables.

## Endpoints

> Not applicable. This service has no inbound API endpoints.

## Request/Response Patterns

> Not applicable.

## Rate Limits

> Not applicable. No rate limiting configured.

## Versioning

> Not applicable. No API versioning — this is a batch job invoked by scheduler.

## OpenAPI / Schema References

> No evidence found in codebase.
