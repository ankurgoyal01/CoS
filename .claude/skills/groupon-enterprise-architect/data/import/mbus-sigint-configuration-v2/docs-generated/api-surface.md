---
service: "mbus-sigint-configuration-v2"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [header-based-client-id]
---

# API Surface

## Overview

The service exposes a REST/JSON API served on port 8080 (HTTP). Consumers identify themselves via the `x-grpn-username` request header, which maps to role-based authorization (`admin`, `full-config-reader`, `change-request-approver`). The API covers six functional resource groups: cluster management, full configuration reads, change-request lifecycle, delete-request lifecycle, deployment scheduling, and GprodConfig. An admin trigger endpoint allows on-demand deployment. The OpenAPI specification is located at `doc/swagger/swagger.yaml`.

## Endpoints

### Admin

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/admin/deploy/{clusterId}/{environmentType}` | Triggers an immediate configuration deployment for a cluster to `PROD` or `TEST` | `admin` role |

### Change Request

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/change-request` | Lists all change requests | authenticated |
| `POST` | `/change-request` | Creates a new change request (destinations, diverts, credentials, redelivery settings) | authenticated |
| `GET` | `/change-request/{id}` | Reads a single change request by ID | authenticated |
| `GET` | `/change-request/{id}/status` | Reads the current status of a change request | authenticated |
| `PUT` | `/change-request/{requestId}/approve` | Approves or rejects a pending change request | `change-request-approver` or `admin` role |

### Cluster

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/cluster` | Lists all MBus clusters | authenticated |
| `POST` | `/cluster` | Creates a new cluster | `admin` role |
| `GET` | `/cluster/{id}` | Reads a cluster by ID | authenticated |
| `PUT` | `/cluster/{id}` | Updates a cluster | `admin` role |
| `DELETE` | `/cluster/{id}` | Deletes a cluster | `admin` role |

### Configuration (Read)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/config/{clusterId}` | Returns full cluster configuration (destinations, diverts, usernames) | `full-config-reader` or `admin` |
| `GET` | `/config/deployment/{clusterId}/{environmentType}` | Returns deployment-ready configuration (queues, topics, roles, credentials, permissions, diverts) for `PROD` or `TEST` | `full-config-reader` or `admin` |
| `GET` | `/config/{clusterId}/destination/{name}` | Returns destination details including access permissions and redelivery settings | authenticated |
| `GET` | `/config/{clusterId}/config-entry/destination/{destinationId}` | Returns config-entry metadata for a destination | authenticated |
| `GET` | `/config/{clusterId}/config-entry/divert/{divertName}` | Returns config-entry metadata for a divert | authenticated |
| `GET` | `/config/{clusterId}/credential/{role}` | Returns credential details (consuming/publishing destinations) for a role | authenticated |

### Delete Request

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/delete-request` | Creates a new delete request for config entries | authenticated |
| `GET` | `/delete-request/{id}` | Reads a delete request by ID | authenticated |

### Deploy Schedule

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/deploy-schedule` | Lists all deployment schedules | authenticated |
| `POST` | `/deploy-schedule` | Creates a new deployment schedule (cluster + environment + cron) | `admin` role |
| `GET` | `/deploy-schedule/{clusterId}/{environmentType}` | Reads schedule for a specific cluster and environment | authenticated |
| `PUT` | `/deploy-schedule/{clusterId}/{environmentType}` | Updates a deployment schedule | `admin` role |
| `DELETE` | `/deploy-schedule/{clusterId}/{environmentType}` | Deletes a deployment schedule | `admin` role |
| `PUT` | `/deploy-schedule/refreshAll` | Refreshes all Quartz triggers from current schedule data | `admin` role |

### GprodConfig

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/gprod-config/{clusterId}` | Reads GprodConfig (impacted systems, data centers, regions) for a cluster | authenticated |
| `PUT` | `/gprod-config` | Updates GprodConfig for a cluster | `admin` role |

## Request/Response Patterns

### Common headers

- `x-grpn-username`: Required for role-based authorization. Maps to configured roles in `clientIds.roles` config block.
- `Content-Type: application/json`: Required for POST/PUT requests with a request body.
- `Accept: application/json`: Expected for all GET responses.

### Error format

> No evidence found in codebase of a documented standard error envelope. Dropwizard default error responses apply (HTTP status codes with plain or JSON error messages).

### Pagination

> No pagination configured. Collection endpoints (`GET /change-request`, `GET /cluster`, `GET /deploy-schedule`) return full arrays.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-path versioning applied to the API. The service is identified as version 2 (`mbus-sigint-config::app`) to distinguish it from the legacy MongoDB-backed version 1 (`mbus-sigint-config::app-v1`). No API-level versioning header or path prefix is in use.

## OpenAPI / Schema References

OpenAPI 2.0 specification: `doc/swagger/swagger.yaml`
Swagger scanner location configured in `doc/swagger/config.yml`: `com.groupon.mbus.sigint.config.resources`
