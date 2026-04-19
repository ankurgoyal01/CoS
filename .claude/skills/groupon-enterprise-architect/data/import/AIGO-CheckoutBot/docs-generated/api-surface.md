---
service: "AIGO-CheckoutBot"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [jwt]
---

# API Surface

## Overview

The `continuumAigoCheckoutBackend` exposes a REST API over HTTPS consumed by two clients: the `continuumAigoChatWidgetBundle` (end-user chat interactions) and the `continuumAigoAdminFrontend` (operator configuration and management). All API routes are grouped under `/api/`. An OpenAPI spec is available at `/api/swagger`. Authentication is enforced via JSON Web Tokens (`jsonwebtoken` 9.0.2).

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Liveness/readiness probe for the backend service | None |

### Conversations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/conversations` | Initiate a new conversation session | JWT |
| GET | `/api/conversations/:id` | Retrieve conversation details and turn history | JWT |
| POST | `/api/conversations/:id/messages` | Submit a user message and receive the bot response | JWT |
| GET | `/api/conversations/:id/messages` | List messages for a conversation | JWT |
| PATCH | `/api/conversations/:id` | Update conversation state or metadata | JWT |
| DELETE | `/api/conversations/:id` | Close or archive a conversation | JWT |

### Projects

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/projects` | List all configured chatbot projects | JWT |
| POST | `/api/projects` | Create a new project | JWT |
| GET | `/api/projects/:id` | Retrieve project configuration | JWT |
| PUT | `/api/projects/:id` | Update project configuration | JWT |
| DELETE | `/api/projects/:id` | Delete a project | JWT |

### Nodes (Decision Tree)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/nodes` | List decision tree nodes for a project | JWT |
| POST | `/api/nodes` | Create a new tree node | JWT |
| GET | `/api/nodes/:id` | Retrieve a specific node | JWT |
| PUT | `/api/nodes/:id` | Update a node's content, conditions, or actions | JWT |
| DELETE | `/api/nodes/:id` | Remove a node from the tree | JWT |

### Analytics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/analytics` | Retrieve aggregated analytics for conversations | JWT |
| GET | `/api/analytics/reports` | Generate and retrieve analytics reports | JWT |

### Simulations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/simulations` | List simulation runs | JWT |
| POST | `/api/simulations` | Trigger a new simulation or replay run | JWT |
| GET | `/api/simulations/:id` | Retrieve simulation run results | JWT |

### OpenAPI

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/swagger` | Serve OpenAPI specification and interactive docs | None |

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <jwt-token>` — required for all authenticated endpoints
- `Content-Type: application/json` — required for all POST/PUT/PATCH request bodies

### Error format

JSON error responses follow a consistent structure:

```json
{
  "error": "<error-code>",
  "message": "<human-readable description>"
}
```

HTTP status codes align with REST conventions: `400` for validation errors, `401` for missing/invalid JWT, `403` for authorization failures, `404` for missing resources, `500` for internal errors.

### Pagination

> No evidence found in the inventory. Pagination behavior for list endpoints is to be confirmed with the service owner.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-path versioning strategy is in use. All endpoints are served under `/api/` without a version prefix. Breaking changes are coordinated with consuming clients directly.

## OpenAPI / Schema References

An interactive OpenAPI specification is served at `/api/swagger` by the running backend. No static OpenAPI file path was identified in the inventory.
