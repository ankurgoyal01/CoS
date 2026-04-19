---
service: "optimus-prime-api"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [ldap, internal]
---

# API Surface

## Overview

Optimus Prime API exposes a REST API under the `/v2/users/{username}/` namespace. All resources are scoped by username, reflecting the per-user ownership model for jobs, groups, runs, and connections. Consumers include data engineering tooling, the Optimus Prime UI, and scheduled internal clients. Authentication is backed by Active Directory / LDAP via the `authDirectoryAdapter`.

## Endpoints

### Jobs

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/users/{username}/jobs` | List all ETL job definitions for a user | LDAP |
| POST | `/v2/users/{username}/jobs` | Create a new ETL job definition | LDAP |
| GET | `/v2/users/{username}/jobs/{jobId}` | Retrieve a specific ETL job definition | LDAP |
| PUT | `/v2/users/{username}/jobs/{jobId}` | Update an existing ETL job definition | LDAP |
| DELETE | `/v2/users/{username}/jobs/{jobId}` | Delete an ETL job definition | LDAP |

### Groups

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/users/{username}/groups` | List groups the user belongs to | LDAP |

### Runs

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/users/{username}/runs` | List job run history for a user | LDAP |
| POST | `/v2/users/{username}/adhoc-runs` | Trigger an ad-hoc (unscheduled) job run | LDAP |

### Connections

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/users/{username}/connections` | List data source connections for a user | LDAP |
| POST | `/v2/users/{username}/connections` | Create a new data source connection | LDAP |
| PUT | `/v2/users/{username}/connections` | Update an existing data source connection | LDAP |

## Request/Response Patterns

### Common headers

> No evidence found in codebase. Standard JTier/Dropwizard/JAX-RS headers are expected (`Content-Type: application/json`, `Accept: application/json`).

### Error format

> No evidence found in codebase. Standard Dropwizard error responses apply — JSON body with error code and message fields.

### Pagination

> No evidence found in codebase. Pagination behavior for list endpoints is not defined in the architecture model.

## Rate Limits

> No rate limiting configured. Rate limiting, if applied, is enforced at the API gateway or load balancer layer outside this service.

## Versioning

The API uses URL path versioning at `/v2/`. All current endpoints are under the v2 namespace.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or proto file is present in the `architecture/` module of this repository.
