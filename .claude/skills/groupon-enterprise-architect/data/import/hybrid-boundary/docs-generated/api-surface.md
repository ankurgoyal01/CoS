---
service: "hybrid-boundary"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, grpc]
auth_mechanisms: [jwt, bearer-token]
---

# API Surface

## Overview

Hybrid Boundary exposes two API surfaces. The administrative REST API is served through AWS API Gateway and backed by the API Lambda (`continuumHybridBoundaryLambdaApi`). It provides full CRUD operations for service registration, endpoint management, authorization policies, traffic shifting, and change history. The xDS gRPC API is served by the Hybrid Boundary Agent (`continuumHybridBoundaryAgent`) on port 7000 and is consumed exclusively by Envoy proxy instances for configuration delivery.

## Endpoints

### Service Management (`/v1/services`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/services` | Register a new service domain | JWT bearer (admin or service owner role) |
| `GET` | `/v1/services` | List all services in a namespace | JWT bearer |
| `GET` | `/v1/services/{serviceName}/{domainName}` | Get a specific service configuration | JWT bearer |
| `PUT` | `/v1/services/{serviceName}/{domainName}` | Update service configuration | JWT bearer (owner or admin) |
| `DELETE` | `/v1/services/{serviceName}/{domainName}` | Delete a service domain (admin only) | JWT bearer (admin only) |

### Endpoint Management (`/v1/services/{serviceName}/{domainName}/endpoints`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/services/{serviceName}/{domainName}/endpoints` | Add an upstream endpoint to a service cluster | JWT bearer (owner or admin) |
| `GET` | `/v1/services/{serviceName}/{domainName}/endpoints` | List endpoints for a service cluster | JWT bearer |
| `PUT` | `/v1/services/{serviceName}/{domainName}/endpoints/{endpointName}` | Update an endpoint configuration | JWT bearer (owner or admin) |
| `DELETE` | `/v1/services/{serviceName}/{domainName}/endpoints/{endpointName}` | Remove an endpoint (must have zero weight) | JWT bearer (owner or admin) |

### Traffic Shift (`/v1/services/{serviceName}/{domainName}/shift`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/services/{serviceName}/{domainName}/shift` | Start a traffic shift between two endpoints | JWT bearer (owner or admin) |
| `GET` | `/v1/services/{serviceName}/{domainName}/shift` | Get current shift status | JWT bearer |
| `DELETE` | `/v1/services/{serviceName}/{domainName}/shift` | Abort an in-progress shift | JWT bearer (owner or admin) |

### Authorization and Policy (`/v1/services/{serviceName}/{domainName}/authorization`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/services/{serviceName}/{domainName}/authorization` | Set authorization configuration for a service | JWT bearer (admin only) |
| `GET` | `/v1/services/{serviceName}/{domainName}/authorization` | Get authorization configuration | JWT bearer |
| `POST` | `/v1/services/{serviceName}/{domainName}/authorization/policies` | Add an access policy | JWT bearer (admin only) |
| `GET` | `/v1/services/{serviceName}/{domainName}/authorization/policies` | List access policies | JWT bearer |
| `PUT` | `/v1/services/{serviceName}/{domainName}/authorization/policies/{policyID}` | Update an access policy | JWT bearer (admin only) |
| `DELETE` | `/v1/services/{serviceName}/{domainName}/authorization/policies/{policyID}` | Remove an access policy | JWT bearer (admin only) |

### History and Versioning (`/v1/services/{serviceName}/{domainName}/versions`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/services/{serviceName}/{domainName}/versions` | List version history for a domain (supports `starttime`/`endtime` query params) | JWT bearer |
| `GET` | `/v1/services/{serviceName}/{domainName}/versions/{version}` | Get a specific historical version | JWT bearer |
| `PUT` | `/v1/services/{serviceName}/{domainName}/versions/{version}` | Revert to a historical version | JWT bearer (owner or admin) |
| `GET` | `/v1/services/history` | List all history across all domains | JWT bearer |

### Permissions (`/v1/permissions`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/permissions` | Get caller's admin status and group memberships | JWT bearer |

### xDS gRPC Server (Agent)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| gRPC stream | `localhost:7000` (configurable via `-listenaddr`) | Serves Envoy xDS resources (clusters, listeners, routes) | mTLS peer certificate |

### Agent Admin HTTP (Agent)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/metrics` | Prometheus metrics for the agent | None (internal) |
| `GET` | `/config` | Current agent configuration and version | None (internal) |

## Request/Response Patterns

### Common headers

- `content-type: application/json` — required for all non-GET requests to the administrative API
- `Authorization: Bearer <jwt>` — required for all API requests; JWT validated against JWKS endpoint

### Error format

All errors from the administrative API return JSON with a `message` field:

```json
{"message": "error description"}
```

HTTP status codes used: `400` (bad request), `401` (unauthenticated), `403` (forbidden), `404` (not found), `409` (conflict with conveyor promotion), `422` (unparseable body), `500` (internal error).

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured. The API is fronted by AWS API Gateway default throttling only.

## Versioning

The administrative API uses URL path versioning. All routes are prefixed with `/v1`. The xDS gRPC API uses Envoy xDS protocol versioning (xDS v3).

## OpenAPI / Schema References

An OpenAPI schema is referenced in `.service.yml` at `openapi-schema/openapi-schema.json`, though the schema directory was not present in the repository snapshot. Refer to the Confluecne documentation at https://groupondev.atlassian.net/wiki/spaces/CR/pages/80541450613 for the current contract.
