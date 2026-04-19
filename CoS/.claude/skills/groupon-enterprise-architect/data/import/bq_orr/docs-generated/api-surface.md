---
service: "bq_orr"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

The BigQuery Orchestration Service (`bq_orr`) does not expose any synchronous HTTP, gRPC, or GraphQL API surface. It is a DAG deployment package, not a running server. All interaction occurs through the Apache Airflow scheduler in the shared Cloud Composer environment. The service's `.service.yml` sets `status_endpoint.prefix: http://` but no endpoint path is defined, and `schema: disabled` is specified explicitly.

## Endpoints

> No evidence found in codebase.

No endpoints are defined. The service is not a web server.

## Request/Response Patterns

> Not applicable

## Rate Limits

> Not applicable

No rate limiting configured. The service delegates execution to Cloud Composer and BigQuery, each of which apply their own quotas.

## Versioning

> Not applicable

No API versioning strategy. DAG versions are managed through git tags and the CI/CD promotion pipeline.

## OpenAPI / Schema References

> No evidence found in codebase.

No OpenAPI spec, proto files, or GraphQL schema exist in this repository.
