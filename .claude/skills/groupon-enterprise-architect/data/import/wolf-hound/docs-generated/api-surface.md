---
service: "wolf-hound"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

The Wolfhound Editor UI exposes a BFF (backend-for-frontend) REST API consumed exclusively by its own frontend clients — the Vue.js workboard SPA and the legacy Backbone-based editorial pages. Routes are defined in `routes/*` and handled by `routeControllers`. All routes proxy, aggregate, or transform data from downstream Continuum services; no data is persisted by this service directly.

## Endpoints

### Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/pages` | List editorial pages | Session |
| GET | `/pages/:id` | Retrieve a single editorial page | Session |
| POST | `/pages` | Create a new editorial page | Session |
| PUT | `/pages/:id` | Update an editorial page | Session |
| DELETE | `/pages/:id` | Delete an editorial page | Session |
| POST | `/pages/:id/publish` | Publish an editorial page | Session |

### Templates

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/templates` | List editorial templates | Session |
| GET | `/templates/:id` | Retrieve a single template | Session |
| POST | `/templates` | Create a new template | Session |
| PUT | `/templates/:id` | Update a template | Session |
| DELETE | `/templates/:id` | Delete a template | Session |

### Scheduling

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/schedules` | List scheduled publish entries | Session |
| POST | `/schedules` | Create a new schedule entry | Session |
| PUT | `/schedules/:id` | Update a schedule entry | Session |
| DELETE | `/schedules/:id` | Delete a schedule entry | Session |

### Taxonomy

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/taxonomy` | List taxonomy categories | Session |
| POST | `/taxonomy` | Create a taxonomy entry | Session |
| PUT | `/taxonomy/:id` | Update a taxonomy entry | Session |

### Reports

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/reports` | Retrieve editorial reports | Session |

### Users and Groups

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/users` | List users (proxied from Users API) | Session |
| GET | `/groups` | List permission groups | Session |
| POST | `/groups` | Create a permission group | Session |

### Deals and Clusters

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals` | Fetch deal divisions and details | Session |
| GET | `/clusters` | Load cluster rules and top cluster content | Session |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all POST/PUT requests
- Session cookie — required for all authenticated routes; validated against `continuumWhUsersApi`

### Error format

> No evidence found for a specific standardised error envelope. Errors follow Express default JSON error handling conventions.

### Pagination

> No evidence found for a specific pagination scheme. Assumed to follow the pagination convention of the proxied downstream service (`continuumWolfhoundApi`).

## Rate Limits

> No rate limiting configured.

## Versioning

Routes are not versioned by URL path prefix. The BFF API is considered an internal API consumed only by its own frontend clients; versioning is managed via coordinated deployment of frontend and backend together.

## OpenAPI / Schema References

> No evidence found for an OpenAPI spec or schema file in the repository.
