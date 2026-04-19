---
service: "janus-yati"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

Janus Yati does not expose any HTTP, gRPC, or RPC API surface. It is a pure data-pipeline service: all interaction occurs through Airflow DAG triggers, Dataproc job submissions, and Kafka topic consumption. There are no inbound network endpoints. Operational control is exercised via the Airflow UI and GCP Dataproc console.

## Endpoints

> No evidence found in codebase.

Janus Yati exposes no network endpoints. The service is invoked exclusively by the Airflow orchestrator via the Dataproc Jobs API.

## Request/Response Patterns

> Not applicable — this service has no inbound API.

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable — no inbound API is exposed.

## Versioning

> Not applicable — no API to version. The artifact version is tracked via `PIPELINE_ARTIFACT_VERSION` environment variable at deploy time and embedded in the JAR path on GCS (e.g., `gs://prod-us-janus-operational-bucket/jar/janus-yati-${PIPELINE_ARTIFACT_VERSION}-jar-with-dependencies.jar`).

## OpenAPI / Schema References

> No evidence found in codebase.

The Swagger configuration file at `doc/swagger/config.yml` is present but does not define any endpoints. No OpenAPI spec, proto files, or GraphQL schema are defined in this repository.
