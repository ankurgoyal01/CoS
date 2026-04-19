---
service: "gazebo"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

Gazebo exposes a Rails-based REST API consumed primarily by its own web UI and internal editorial tooling. The API is organized around core editorial entities: deals, tasks, users, merchandising checklists, and content recovery. A versioned `/v2/` prefix is used for deal-related endpoints. Feature flag state can be queried via a dedicated endpoint. JSON API endpoints under `/api/` serve structured data for tasks and translation requests.

## Endpoints

### Deals

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/deals` | Fetch deal list | Session |
| PUT | `/v2/deals` | Update deal information | Session |
| GET | `/v2/deals/search` | Search deals by query parameters | Session |

### Teams

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/teams/:id` | Retrieve team information by ID | Session |

### Content Recovery

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/recycle_bin` | List recycled content items | Session |
| POST | `/recycle_bin` | Restore or manage recycled content | Session |

### Merchandising Checklist

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchandising_checklist` | Retrieve checklist for a deal | Session |
| POST | `/merchandising_checklist` | Create a new checklist entry | Session |
| PUT | `/merchandising_checklist` | Update checklist item state | Session |

### Tasks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/tasks` | List editorial tasks | Session |
| PUT | `/tasks` | Claim, unclaim, or complete a task | Session |

### Users

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/users` | List users | Session |
| POST | `/users` | Create user | Session |
| PUT | `/users` | Update user profile or permissions | Session |

### JSON API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/tasks` | JSON API for task data | Session |
| GET | `/api/translation_request` | JSON API for translation requests | Session |

### Feature Flags

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/features/:name` | Query feature flag status by name | Session |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for JSON API endpoints
- `Accept: application/json` for API consumers
- Session cookie for authentication on all endpoints

### Error format

> No evidence found in codebase. Standard Rails error response format expected (HTTP status code with JSON body for API endpoints).

### Pagination

Kaminari gem (v0.16.2) is used for pagination on list endpoints. Page and per-page parameters are expected to follow Rails/Kaminari conventions (e.g., `?page=2&per_page=25`).

## Rate Limits

> No rate limiting configured.

## Versioning

Deal endpoints use a URL path version prefix (`/v2/`). Other endpoints are unversioned. No evidence of header-based or query-parameter versioning.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema discovered.
