---
service: "janus-metric"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

janus-metric is a batch Spark job service. It does not expose any inbound HTTP, gRPC, or messaging API. The service is triggered exclusively by Apache Airflow DAG schedules on Google Cloud Dataproc. All outbound calls go to the Janus Metadata Service (`janus-web-cloud`) — see [Integrations](integrations.md) for details.

## Endpoints

> Not applicable. This service exposes no inbound endpoints.

## Request/Response Patterns

> Not applicable.

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable. No inbound API surface exists.

## Versioning

> Not applicable.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema found in the repository.
