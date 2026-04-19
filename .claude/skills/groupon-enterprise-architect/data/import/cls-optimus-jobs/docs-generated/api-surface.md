---
service: "cls-optimus-jobs"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

CLS Optimus Jobs is a pure batch data pipeline service. It does not expose any HTTP endpoints, gRPC services, or other synchronous API surfaces. All interactions occur through the Optimus job scheduler at `https://optimus.groupondev.com/` — job execution is triggered by Optimus schedules or manually via the Optimus UI. There is no programmable API surface on this service.

## Endpoints

> Not applicable. This service does not expose any API endpoints. Job invocation is managed exclusively through the Optimus control plane.

## Request/Response Patterns

> Not applicable.

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable. No rate limiting configured.

## Versioning

> Not applicable. Job definitions are version-controlled via this Git repository. There is no API versioning strategy.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema exist in this repository.
