---
service: "janus-muncher"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

Janus Muncher exposes no inbound HTTP endpoints or APIs. It is a batch Spark pipeline invoked exclusively by Airflow DAG tasks via the Google Cloud Dataproc job submission API. The service has no web server, no REST interface, and no gRPC or GraphQL surface. All interaction occurs through GCS file paths (input and output), the Ultron State API (outbound), and the Janus Metadata API (outbound).

## Endpoints

> Not applicable. This service does not expose any inbound API endpoints.

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

> Not applicable. No API schema files exist in this repository.
