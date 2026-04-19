---
service: "ultron-ui"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [ldap]
---

# API Surface

## Overview

Ultron UI exposes a REST HTTP API consumed by the AngularJS single-page application running in the operator's browser. Every endpoint requires LDAP authentication. The API is a thin proxy layer: each route receives the operator's request, authenticates it via LDAP, and forwards it to `continuumUltronApi`. Responses are JSON unless otherwise noted.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/heartbeat` | Liveness health check | None |

### Groups

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/groups` | List all job groups | LDAP |
| POST | `/groups` | Create a new job group | LDAP |
| PUT | `/groups` | Update an existing job group | LDAP |
| DELETE | `/groups` | Delete a job group | LDAP |

### Jobs

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/job/list/:groupId` | List all jobs belonging to a group | LDAP |
| POST | `/job/create` | Create a new job definition | LDAP |
| GET | `/job/fetch/:jobId` | Fetch details for a specific job | LDAP |
| GET | `/job/trend` | Retrieve job performance trend data | LDAP |
| GET | `/job/dependency` | Retrieve job dependency graph data | LDAP |

### Lineage

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/lineage/resource` | Retrieve data resource lineage information | LDAP |

### Instances

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/instance/create` | Create a new job execution instance | LDAP |
| PUT | `/instance/update` | Update the status of an existing job instance | LDAP |

### Resources

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/resource/all` | Retrieve all registered data resources | LDAP |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST/PUT request bodies
- LDAP credentials are validated per request; session or token mechanism managed by Play Framework

### Error format

> No evidence found in inventory for a standardised error response schema. Error handling delegated to `continuumUltronApi` responses, surfaced as-is to the browser client.

### Pagination

> No evidence found for pagination conventions on list endpoints.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL versioning strategy is applied. All routes are unversioned. API evolution is managed through coordinated deployment with `continuumUltronApi`.

## OpenAPI / Schema References

> No evidence found for an OpenAPI specification or schema file in this repository.
