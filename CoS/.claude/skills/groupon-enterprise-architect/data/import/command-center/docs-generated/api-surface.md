---
service: "command-center"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [http]
auth_mechanisms: [session]
---

# API Surface

## Overview

Command Center exposes an internal HTTP web interface via `continuumCommandCenterWeb` (Ruby on Rails). All routes are internal-only and restricted to authenticated Groupon operations and support staff. The API surface consists of tool-specific controller endpoints that accept operational requests, validate inputs, and either respond synchronously or schedule background jobs via Delayed Job. There is no public-facing or partner-accessible API.

## Endpoints

### Tool Controllers (`cmdCenter_webControllers`)

> No specific route paths are defined in the architecture DSL. The following groups reflect the component and integration model traced from `architecture/models/components/command-center-web-components.dsl` and `architecture/models/relations.dsl`.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `/tools/*` | Tool listing, execution initiation, and status retrieval for deal, order, voucher, and place tools | Session |
| GET/POST | `/jobs/*` | Background job status, progress inspection, and result retrieval | Session |
| GET/POST | `/reports/*` | Report artifact listing and CSV download from object storage | Session |
| GET/POST | `/admin/*` | User and tool administration workflows | Session |

> Specific route paths are defined in the Rails routing layer of the command-center application repository and are not enumerated in the architecture DSL. The groups above reflect the capability areas evidenced by container and component definitions.

## Request/Response Patterns

### Common headers

- Standard Rails session cookie for authentication
- CSRF token required on all state-mutating requests (Rails default behavior)

### Error format

> No evidence found in the architecture inventory. Standard Rails error pages and JSON error responses are expected based on the Rails framework convention.

### Pagination

> No evidence found in the architecture inventory.

## Rate Limits

> No rate limiting configured. Command Center is an internal tool accessible only to authenticated Groupon staff over internal networks.

## Versioning

No API versioning strategy is evidenced in the architecture inventory. Command Center is an internal tool with no external consumers requiring version stability guarantees.

## OpenAPI / Schema References

> No evidence found. No OpenAPI spec, proto files, or GraphQL schema are referenced in the architecture inventory.
