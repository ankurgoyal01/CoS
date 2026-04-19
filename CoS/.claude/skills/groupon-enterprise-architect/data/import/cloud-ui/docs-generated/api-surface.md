---
service: "cloud-ui"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [public]
---

# API Surface

## Overview

Cloud UI exposes two API surfaces: the **Cloud Backend API** (served by the Encore Go service at `/cloud-backend/*`) is the primary machine-facing REST API consumed by the Next.js frontend; and the **Next.js API Routes** (served at `/api/*`) provide lightweight server-side helpers for runtime configuration and local health. All Cloud Backend endpoints use JSON request/response bodies and are declared with `//encore:api public` — Encore's framework-level routing; no additional OAuth or API key auth is configured in code.

## Endpoints

### Organizations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/cloud-backend/organizations` | Create a new organization (DNS-1123 name required) | Public |
| `GET` | `/cloud-backend/organizations` | List organizations with pagination | Public |
| `GET` | `/cloud-backend/organizations/:id` | Retrieve a specific organization by ID | Public |
| `PUT` | `/cloud-backend/organizations/:id` | Update display name or description | Public |
| `DELETE` | `/cloud-backend/organizations/:id` | Delete organization (fails if applications exist) | Public |

### Applications

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/cloud-backend/applications` | Create a new application with components; validates organization, image registry, and port | Public |
| `GET` | `/cloud-backend/applications` | List applications with pagination; supports `organizationId` filter | Public |
| `GET` | `/cloud-backend/applications/:id` | Retrieve application by ID with full config (autoscaling, components, probes, storage) | Public |
| `PUT` | `/cloud-backend/applications/:id` | Update application; supports environment-specific component updates via `targetEnvironment` | Public |
| `DELETE` | `/cloud-backend/applications/:id` | Delete application and its deployments (cascade) | Public |
| `GET` | `/cloud-backend/applications/:id/diff` | Return configuration diff between current state and last deployment snapshot | Public |

### Deployments

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/cloud-backend/applications/:appId/deployments` | Create a deployment record in `queued` phase for an application | Public |
| `GET` | `/cloud-backend/applications/:appId/deployments` | List deployments for an application with pagination | Public |
| `GET` | `/cloud-backend/applications/:appId/deployments/:deploymentId` | Retrieve a specific deployment record | Public |

### Git Sync

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/cloud-backend/applications/:id/sync-to-git` | Render Helm values, commit config files to the application's Git repository, and advance deployment phase | Public |

### Deployment Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/cloud-backend/deployments/:deploymentId/status` | Get current deployment phase and status; polls Jenkins when phase is `synced` or `building`; returns Deploybot URL when `ready_to_deploy` | Public |

### Helm Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/cloud-backend/helm/render` | Render component config to Helm values JSON | Public |
| `POST` | `/cloud-backend/helm/render-yaml` | Render component config to Helm values YAML string | Public |
| `POST` | `/cloud-backend/helm/validate` | Validate component configuration against Helm constraints | Public |
| `POST` | `/cloud-backend/helm/chart-for-workload` | Resolve chart name and latest version for a workload type (`api` or `worker`) from Artifactory | Public |
| `POST` | `/cloud-backend/helm/validate-version` | Check whether a specific chart version exists in Artifactory | Public |
| `POST` | `/cloud-backend/helm/render-template` | Download chart from Artifactory, map config to values, and render full Kubernetes manifests | Public |
| `POST` | `/cloud-backend/helm/clear-cache` | Evict in-memory index cache, chart file cache, and Helm SDK cache directories | Public |

### Health and Readiness (Cloud Backend)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/cloud-backend/health` | Returns service name, version, environment, and uptime | Public |
| `GET` | `/cloud-backend/ready` | Returns readiness status with dependency checks | Public |

### Next.js API Routes (Frontend)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/health` | Local frontend health check returning `{ status, timestamp, service, version }` | Public |
| `GET` | `/api/config` | Returns resolved backend API URL, Node.js environment, and app version for frontend runtime bootstrap | Public |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` required for all POST and PUT requests to Cloud Backend endpoints.

### Error format

Encore returns errors using its typed error model. The HTTP response body contains a JSON object with a `code` field (Encore error code such as `invalid_argument`, `not_found`, `already_exists`, `internal`) and a `message` string. A `meta` map is included for additional context (e.g., field name, violating value).

### Pagination

List endpoints accept `page` (1-based, defaults to 1) and `limit` (defaults to 10, max 100 for applications; max 100 for organizations) as query parameters. Responses include `items` array and `total` count.

## Rate Limits

No rate limiting configured.

## Versioning

No API versioning strategy is implemented. All endpoints are served at their current paths without a version prefix.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema found in the repository. Encore auto-generates its own API schema from `//encore:api` annotations.
