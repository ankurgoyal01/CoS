---
service: "aes-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

AES exposes a REST API (Swagger 2.0, versioned under `/api/v1/`) for managing scheduled and published audience lifecycle, querying extended audience info, triggering utility jobs, and executing GDPR erasure operations. The API is consumed primarily by the Display Wizard marketing UI and by internal automation/admin tooling. An OpenAPI spec is maintained at `doc/swagger/swagger.yaml`.

## Endpoints

### Audiences (Extended Info)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v1/audiences` | Retrieve paginated extended audience info (AES + AMS + partner metadata) | Internal |
| `POST` | `/api/v1/audiences/updateAmsCache` | Refresh in-memory AMS audience cache | Internal |
| `POST` | `/api/v1/audiences/updateFBCache` | Refresh in-memory Facebook audience cache | Internal |

### Metadata (Internal Testing)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v1/metadata/{id}` | Retrieve full AES audience record by ID (internal testing only) | Internal |
| `GET` | `/api/v1/metadata/{id}/executeJob` | Manually trigger export job for a given audience ID (internal testing only) | Internal |

### Published Audiences

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v1/publishedAudiences` | List all published audiences (paginated) | Internal |
| `POST` | `/api/v1/publishedAudiences` | Create a new published audience record | Internal |

### Scheduled Audiences

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v1/scheduledAudiences` | List all scheduled audiences (paginated) | Internal |
| `POST` | `/api/v1/scheduledAudiences` | Create a new scheduled audience (optionally creates Quartz job) | Internal |
| `GET` | `/api/v1/scheduledAudiences/{id}` | Get scheduled audience by AES ID | Internal |
| `PUT` | `/api/v1/scheduledAudiences/{id}` | Update scheduled audience status | Internal |
| `DELETE` | `/api/v1/scheduledAudiences/{id}` | Delete scheduled audience by ID | Internal |
| `PUT` | `/api/v1/scheduledAudiences/{id}/pause` | Pause a scheduled audience and its Quartz trigger | Internal |
| `PUT` | `/api/v1/scheduledAudiences/{id}/resume` | Resume a paused scheduled audience | Internal |
| `GET` | `/api/v1/scheduledAudiences/cia/{ciaId}` | Get AES target configuration by CIA audience ID | Internal |
| `GET` | `/api/v1/scheduledAudiences/recoverTriggers` | Recover Quartz triggers stuck in error state for an ID range | Internal |

### Utility / Admin

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/api/v1/utils/runAudienceStatsUpdate` | Trigger audience stats refresh (internal testing only) | Internal |
| `GET` | `/api/v1/utils/runUpdateCustomerInfoJob` | Trigger customer-info update job for a date range (internal testing only) | Internal |

### GDPR Erasure

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `DELETE` | `/api/v1/utils/erasure/deleteCustomer/{customerId}` | Part 1: Delete customer from AES Postgres tables | Internal |
| `DELETE` | `/api/v1/utils/erasure/deleteCerebro/{customerId}` | Part 2: Remove customer from denylist and Cerebro tables | Internal |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/heartbeat.txt` | Health check endpoint | None |
| `POST` | `/heartbeat.txt` | Mark service healthy | Internal |
| `DELETE` | `/heartbeat.txt` | Mark service unhealthy | Internal |

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` for POST/PUT request bodies
- `Accept: application/json` or `text/plain` depending on endpoint

### Error format
> No evidence found in codebase for a standardised error response envelope beyond HTTP status codes.

### Pagination
All list endpoints support `page-size` (integer, default 5000) and `page-number` (integer, default 1) as query parameters.

## Rate Limits

> No rate limiting configured within the service. Rate limiting on ad-platform APIs (Facebook, Google, etc.) is governed by each partner's own quotas.

## Versioning

URL path versioning: all business endpoints are prefixed with `/api/v1/`.

## OpenAPI / Schema References

- OpenAPI 2.0 spec: `doc/swagger/swagger.yaml` / `doc/swagger/swagger.json`
- Swagger config: `doc/swagger/config.yml`
- Production Swagger UI: `https://aes-service.production.service.us-central1.gcp.groupondev.com/swagger/?url=.../swagger.json`
