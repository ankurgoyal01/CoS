---
service: "metro-ui"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest, http]
auth_mechanisms: [session, itier-auth]
---

# API Surface

## Overview

Metro UI exposes both browser-facing HTML routes (server-side rendered pages) and JSON API endpoints consumed by the frontend bundles. Browser routes serve the deal creation/editing UI. JSON endpoints proxy AI content generation and deal asset upload operations to downstream services. All endpoints are served by the `continuumMetroUiService` Node.js/itier-server process.

## Endpoints

### Merchant Deal Creation UI

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant/center/draft` | Serves the main merchant deal creation and draft management UI | itier session |

### AI Content Generation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v2/merchants/{id}/mdm/deals/{id}/ai/contentai` | Triggers AI-assisted content generation for deal copy (titles, descriptions) | itier session |

### Deal Asset Upload

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v2/merchants/{id}/mdm/deals/{id}/upload` | Accepts deal image/asset uploads and forwards to storage backend | itier session |

### AI Content Generation (Internal Action)

| Method | Path / Action | Purpose | Auth |
|--------|------|---------|------|
| POST | `generate_ai_content` | Internal controller action that orchestrates AI content generation via GenAI Service | Internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for JSON API endpoints
- `Accept: text/html` — expected for server-rendered page routes
- itier session cookie — propagated automatically by the itier framework for auth context

### Error format

> No evidence found in the inventory for a documented error response schema. Error handling follows itier-server framework conventions; HTTP status codes and JSON error bodies are expected for API endpoints.

### Pagination

> Not applicable — the deal creation UI is a single-page form flow; no paginated list endpoints are exposed by this service.

## Rate Limits

> No rate limiting configured at the service level. Rate limiting, if any, is enforced upstream by `apiProxy` or the Kubernetes ingress layer.

## Versioning

API routes under `/v2/` follow a URL path versioning strategy. The UI route `/merchant/center/draft` is unversioned.

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec, proto files, or GraphQL schema committed to this repository. Endpoint contracts are enforced via `itier-merchant-api-client 1.1.8`.
