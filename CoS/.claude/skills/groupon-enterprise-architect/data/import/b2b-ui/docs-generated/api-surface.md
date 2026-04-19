---
service: "b2b-ui"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [jwt, cookie]
---

# API Surface

## Overview

The RBAC UI exposes a set of Next.js API routes that form the Backend-for-Frontend (BFF) layer. These routes are consumed exclusively by the browser-side React application. All routes sit under the `/api` prefix. Session middleware validates an auth cookie/JWT before requests reach any BFF route. A separate metrics endpoint accepts client-side telemetry. A UMAPI client ID is used for identity context on both client and server.

## Endpoints

### Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/login` | Initiates or validates login session | Cookie / JWT |

### RBAC Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/rbac` | Lists RBAC entities (roles, permissions, categories) | Session middleware (JWT cookie) |
| POST | `/api/rbac/users/create` | Creates a new user across NA and EMEA regions with permission checks | Session middleware (JWT cookie) |

### Observability

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/metrics/log` | Receives browser/client telemetry and writes structured server logs | None (internal) |

### Bot Detection

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/botland` | Landing page for requests redirected by Akamai bot-detection middleware | None |

## Request/Response Patterns

### Common headers
- Requests passing through Session Middleware carry injected RBAC identity headers that identify the requester for downstream services.
- `NEXT_PUBLIC_RBAC_CLIENT_ID` is passed as an OAuth2-style client identifier in API calls to `continuumRbacService`.

### Error format

> No evidence found in codebase for a documented standard error response schema. Errors are expected to follow Next.js API route default behavior (JSON body with `error` field).

### Pagination

> No evidence found in codebase for a documented pagination pattern on BFF routes. Pagination, if any, is delegated to the downstream `continuumRbacService` and forwarded transparently.

## Rate Limits

> No rate limiting configured at the BFF layer. Rate limiting, if any, is enforced by Akamai at the edge and by `continuumRbacService` downstream.

## Versioning

All BFF API routes are unversioned. The RBAC client is generated from `libs/vpcs/core/rbac-client/swagger.yml` using `swagger-typescript-api` and tracks the RBAC v2 API version of `continuumRbacService`.

## OpenAPI / Schema References

- RBAC client Swagger spec: `libs/vpcs/core/rbac-client/swagger.yml`
- Generated TypeScript client: `libs/vpcs/core/rbac-client/src/lib/rbac-client.ts` (generated via `npm run generate-rbac-client`)
