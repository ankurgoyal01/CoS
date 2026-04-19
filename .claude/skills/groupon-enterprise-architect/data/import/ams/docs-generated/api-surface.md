---
service: "ams"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [aws-sigv4]
---

# API Surface

## Overview

AMS exposes a REST/JSON API implemented via JAX-RS (Jersey/Dropwizard) through the `ams_apiResources` component. The API is consumed by internal Groupon platform services — primarily ads targeting, CRM pipelines, and reporting workloads — to manage audience definitions, trigger computation, retrieve exports, and query audit history.

## Endpoints

### Attribute and Criteria

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/ca-attributes/{id}` | Retrieve a specific CA attribute by ID | AWS SigV4 |
| GET/POST | `/criteria` | List or create audience criteria definitions | AWS SigV4 |
| GET/POST | `/attribute` | List or create audience attributes | AWS SigV4 |

### Audience Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/audience/*` | Retrieve audience definitions and status | AWS SigV4 |
| POST | `/audience/*` | Create or update audience definitions | AWS SigV4 |
| PUT | `/audience/*` | Modify existing audience records | AWS SigV4 |
| DELETE | `/audience/*` | Remove audience definitions | AWS SigV4 |

### Export

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/export/*` | Retrieve export job status and results | AWS SigV4 |
| POST | `/export/*` | Trigger audience export orchestration | AWS SigV4 |

### Scheduling

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/schedule/*` | Retrieve audience execution schedules | AWS SigV4 |
| POST | `/schedule/*` | Create or update audience execution schedules | AWS SigV4 |
| DELETE | `/schedule/*` | Remove execution schedules | AWS SigV4 |

### Custom Query

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/custom-query/*` | Execute custom queries against audience data | AWS SigV4 |
| GET | `/custom-query/*` | Retrieve custom query definitions and results | AWS SigV4 |

### Operational

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/getAuditLog` | Retrieve audience lifecycle audit log entries | AWS SigV4 |
| POST | `/bootstrapApplication` | Bootstrap application state on startup | Internal |
| GET | `/grpn/healthcheck` | Service health check | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — all request and response bodies use JSON
- AWS SigV4 signature headers for authenticated endpoints

### Error format

Standard Dropwizard error responses — HTTP status code with a JSON body containing an `errors` array or `message` field.

### Pagination

> No evidence found for a specific pagination contract. Consumers should verify with the service team.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-path versioning scheme is in evidence. The API is versioned implicitly through deployment; consumers must coordinate with the AMS team for breaking changes.

## OpenAPI / Schema References

> No OpenAPI spec or schema file discovered in the repository inventory. Contact the Audience Service / CRM team for a current schema.
