---
service: "optimus-prime-ui"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [session-cookie, header-injection]
---

# API Surface

## Overview

Optimus Prime UI is a browser SPA — it does not expose its own HTTP API for other services to consume. It acts as a pure API consumer. The nginx reverse proxy embedded in the Docker container exposes two proxy paths that forward browser requests to backend services: `/api/` proxied to `optimus-prime-api` and `/refresh-api/` proxied to the `refresh-api--v2` service. The UI itself communicates exclusively with these proxied backend paths. A static health check endpoint is also served by nginx.

The mock data files under `src/mocks/api/` document the full shape of the backend API contracts as seen by the UI, covering v1 and v2 API versions.

## Endpoints (Nginx Proxy — served by this container)

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Kubernetes liveness probe; returns `200 ok` | None |

### API Proxy (forwarded to `optimus-prime-api`)

| Method | Path (as seen by browser) | Purpose | Auth |
|--------|--------------------------|---------|------|
| GET | `/api/v1/jobs` | List all ETL jobs | Session cookie |
| GET | `/api/v1/jobs/:id` | Get a single job by ID | Session cookie |
| POST | `/api/v1/jobs` | Create a new ETL job | Session cookie |
| PUT | `/api/v1/jobs/:id` | Update an existing ETL job | Session cookie |
| DELETE | `/api/v1/jobs/:id` | Delete an ETL job | Session cookie |
| GET | `/api/v1/jobs/runs/executions` | List job run executions | Session cookie |
| GET | `/api/v1/connections` | List all data connections | Session cookie |
| GET | `/api/v1/connection-types` | List supported connection types | Session cookie |
| GET | `/api/v1/groups` | List workspace groups | Session cookie |
| GET | `/api/v1/variables/builtin` | List built-in job variables | Session cookie |
| GET | `/api/v2/connections` | List connections (v2) | Session cookie |
| GET | `/api/v2/datafetcher` | List data fetcher runs | Session cookie |
| GET | `/api/v2/datafetcher/download` | Download data fetcher results | Session cookie |

### Refresh API Proxy (forwarded to `refresh-api--v2`)

| Method | Path (as seen by browser) | Purpose | Auth |
|--------|--------------------------|---------|------|
| * | `/refresh-api/*` | All requests forwarded to `refresh-api--v2/api/` | Session cookie |

## Request/Response Patterns

### Common headers

- User identity is injected by nginx from the Groupon SSO layer as request headers: `X-GRPN-USERNAME`, `X-GRPN-EMAIL`, `X-GRPN-FIRSTNAME`, `X-GRPN-LASTNAME`
- nginx sets cookies `op-user`, `op-email`, `op-firstname`, `op-lastname` on HTML responses for the UI to consume
- All API calls use `Content-Type: application/json`
- All API responses use a `{ "data": [...] }` envelope shape (confirmed by all mock fixtures)

### Error format

> No evidence found in codebase for a standardized error response schema from the backend. The UI handles empty response bodies via the `onEmptyResponseBody` EventBus event, which forwards the exception to Google Analytics.

### Pagination

> No evidence found in codebase for a pagination protocol in mock API responses. The connections and jobs list responses return flat arrays inside the `data` envelope.

## Rate Limits

> No rate limiting configured at the nginx proxy layer. Rate limits, if any, are enforced by the `optimus-prime-api` backend.

## Versioning

The backend API supports two versioning prefixes visible to the UI: `/api/v1/` (legacy) and `/api/v2/` (current). The UI consumes both depending on the resource. There is no API versioning strategy owned by this frontend service itself.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exist in this repository. API contracts are documented implicitly by the MSW mock fixtures under `src/mocks/api/`.
