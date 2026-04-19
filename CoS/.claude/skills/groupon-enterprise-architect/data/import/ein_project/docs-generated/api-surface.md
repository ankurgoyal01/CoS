---
service: "ein_project"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, jwt]
---

# API Surface

## Overview

ProdCat exposes a REST API consumed by deployment tooling (DeployBot, CI pipelines) and internal Groupon engineers via the web UI. The primary use cases are: submitting change requests for approval gating (`/api/changes/`), performing inline policy checks without persisting a record (`/api/check/`), and reading the auditable change log (`/api/change_log/`). Supporting endpoints provide configuration data for regions, approvers, change windows, and policies.

## Endpoints

### Change Requests

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/changes/` | Submit a new change request for approval gating | Session / JWT |

### Change Log

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/change_log/` | Retrieve auditable log of past change requests | Session / JWT |

### Policy Check

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/check/` | Run a policy validation check without persisting a change record | Session / JWT |

### Reference Data

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/regions/` | List configured deployment regions | Session / JWT |
| GET | `/api/approvers/` | List configured approvers | Session / JWT |
| GET | `/api/change_windows/` | List defined change windows and freeze periods | Session / JWT |
| GET | `/api/clients/` | List registered client systems | Session / JWT |
| GET | `/api/holiday_policies/` | List holiday-based deployment freeze policies | Session / JWT |
| GET | `/api/settings/` | Retrieve runtime configuration settings | Session / JWT |
| GET | `/api/scheduled_locks/` | List currently active scheduled region locks | Session / JWT |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/heartbeat/` | Liveness probe — returns service health status | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all POST requests
- `Accept: application/json` — expected on all requests

### Error format

Errors follow the Django REST Framework default envelope: an object with field-level error arrays for validation failures, or a `detail` string for authentication and permission errors.

### Pagination

> No evidence found of a specific pagination scheme. DRF default cursor/page-number pagination may apply on list endpoints.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL path versioning is applied. All endpoints are served under `/api/` without a version prefix.

## OpenAPI / Schema References

> No evidence found of a committed OpenAPI spec. Schema is derivable from Django REST Framework introspection at runtime.
