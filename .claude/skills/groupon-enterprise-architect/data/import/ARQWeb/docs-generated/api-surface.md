---
service: "ARQWeb"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest", "html"]
auth_mechanisms: ["session"]
---

# API Surface

## Overview

ARQWeb exposes an HTTP surface through its Flask application (`continuumArqWebApp`). The application serves both a browser-rendered UI (HTML via Flask templates) and JSON API endpoints used by the UI and potentially internal tooling. Endpoints are organized into logical groups: access request submission and management, approval workflows, admin and SOX administration, and onboarding flows. All routes are handled by the `arqWebRouting` component (Flask Blueprints).

> No OpenAPI specification or explicit route manifest was found in the repository inventory. The endpoint groups below are derived from the architecture model describing Flask blueprints and request handlers for UI and API endpoints.

## Endpoints

### Access Requests

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/requests` | Lists access requests visible to the current user | Session |
| POST | `/requests` | Submits a new access request | Session |
| GET | `/requests/<id>` | Retrieves detail for a specific access request | Session |
| POST | `/requests/<id>/approve` | Approves a pending access request | Session (approver) |
| POST | `/requests/<id>/reject` | Rejects a pending access request | Session (approver) |

### Admin and SOX Workflows

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/admin` | Admin dashboard for access governance | Session (admin) |
| GET | `/admin/requests` | Lists all requests with admin-level filters | Session (admin) |
| POST | `/admin/requests/<id>/action` | Performs admin-level action on a request | Session (admin) |

### Onboarding

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/onboarding` | Onboarding workflow entry for new employees | Session |
| POST | `/onboarding` | Submits onboarding access request batch | Session |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Service health check | None |

> Specific path patterns are inferred from the Flask blueprint architecture. Actual route definitions should be confirmed from the application source.

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` for API endpoints
- Session cookie for authenticated requests

### Error format
> No evidence found in codebase. Standard Flask error responses are expected (JSON body with error message for API routes, HTML error pages for UI routes).

### Pagination
> No evidence found in codebase.

## Rate Limits

> No rate limiting configured — no evidence found in codebase.

## Versioning

> No evidence found in codebase. No URL versioning prefix (e.g., `/v1/`) was identified in the architecture model.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema were identified in the repository inventory.
