---
service: "mbus-sigint-frontend"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, csrf-token, okta-headers]
---

# API Surface

## Overview

The service exposes two distinct API layers to browser clients. The first is a set of first-party endpoints served directly by the Node.js backend (app config, session info, SPA shell, web manifest). The second is a transparent proxy layer at `/api/{serviceId}/*` that forwards requests to upstream services (`mbus-sigint-config` and `service-portal`). All state-changing proxy calls (POST, PUT, DELETE) require a CSRF token in the `x-csrf-token` request header.

The OpenAPI specification is located at `doc/openapi.yml`.

## Endpoints

### SPA Shell

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/*` | Serves the React SPA HTML shell for all non-API routes | Okta (Hybrid Boundary) |

### Frontend Server (First-Party)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/mbus-sigint-frontend/app-config` | Returns runtime application configuration (Jira base URL, app name, Service Portal base URL) | Okta (Hybrid Boundary) |
| `GET` | `/api/mbus-sigint-frontend/session-info` | Returns current authenticated user details (username, email, first/last name) and a CSRF token | Okta (Hybrid Boundary) |
| `GET` | `/manifest.webmanifest` | Returns the Progressive Web App manifest (name, icons, start URL, display mode) | None |

### API Proxy (Forwarded to Upstreams)

All paths under `/api/{serviceId}/*` are transparently proxied to the upstream service identified by `serviceId`. The `x-csrf-token` header is stripped before forwarding.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/mbus-sigint-config/cluster` | Lists all MessageBus clusters | Okta |
| `GET` | `/api/mbus-sigint-config/config/{cluster}` | Retrieves full cluster configuration | Okta |
| `GET` | `/api/mbus-sigint-config/config/{cluster}/destination/{destinationName}` | Retrieves destination details | Okta |
| `GET` | `/api/mbus-sigint-config/config/{cluster}/credential/{role}` | Retrieves credential details for a role | Okta |
| `GET` | `/api/mbus-sigint-config/config/{cluster}/config-entry/divert/{divertName}` | Retrieves divert config entry details | Okta |
| `GET` | `/api/mbus-sigint-config/config/{cluster}/config-entry/destination/{destinationName}` | Retrieves destination config entry details | Okta |
| `GET` | `/api/mbus-sigint-config/change-request` | Lists all pending change requests | Okta |
| `GET` | `/api/mbus-sigint-config/change-request/{requestId}` | Retrieves a specific change request | Okta |
| `POST` | `/api/mbus-sigint-config/change-request` | Submits a new configuration change request | Okta + CSRF |
| `PUT` | `/api/mbus-sigint-config/change-request/{requestId}/approve` | Approves or rejects a change request | Okta + CSRF |
| `POST` | `/api/mbus-sigint-config/delete-request` | Submits a delete request for a destination or divert | Okta + CSRF |
| `GET` | `/api/mbus-sigint-config/deploy-schedule` | Lists all deploy schedules | Okta |
| `GET` | `/api/mbus-sigint-config/deploy-schedule/{clusterId}/{environmentType}` | Retrieves deploy schedule for a cluster/environment | Okta |
| `PUT` | `/api/mbus-sigint-config/deploy-schedule/{clusterId}/{environmentType}` | Updates a deploy schedule | Okta + CSRF |
| `POST` | `/api/mbus-sigint-config/admin/deploy/{clusterId}/{environmentType}` | Triggers an ad-hoc cluster deployment | Okta + CSRF |
| `GET` | `/api/service-portal/services.json` | Retrieves list of all service names for autocomplete | Okta |

## Request/Response Patterns

### Common headers

- `x-grpn-username`, `x-grpn-email`, `x-grpn-firstname`, `x-grpn-lastname` — injected by the Hybrid Boundary layer from Okta; consumed by `sessionInfo` action
- `GRPN-Client-Id: mbus-sigint-frontend` — appended by `ServicePortalClient` on all outbound service-portal calls
- `x-csrf-token` — required on all state-changing proxy requests; stripped before forwarding upstream

### Error format

> No standardised error envelope is documented in `doc/openapi.yml`. Error responses propagate from upstream services through the proxy as-is.

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

No API versioning strategy is applied. The service uses a single URL namespace without version prefixes. The `mbus-sigint-config` upstream is addressed by service ID, not by version.

## OpenAPI / Schema References

- OpenAPI 3.0 specification: `doc/openapi.yml`
- Hybrid Boundary (production): `https://mbus-sigint-frontend.production.service`
- Hybrid Boundary (staging): `https://mbus-sigint-frontend.staging.service`
