---
service: "img-service-primer"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [ldap-group-header]
---

# API Surface

## Overview

The Image Service Primer exposes a REST API over HTTP on port 8080. All endpoints are administrative — they trigger long-running cache priming processes and are intended for operator use, not programmatic client consumption. There are no SLAs defined for the API surface. The service does not expose a public API; it is accessed via internal VIPs (e.g. `http://gims-primer-vip.snc1`) or the external management host (`https://gims-primer-us.groupondev.com`). Authorization for the image delete endpoint is enforced via LDAP group membership passed in the `x-grpn-groups` header.

## Endpoints

### Preload — Scheduled Trigger

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/preload/cron/immediately` | Immediately trigger the scheduled daily deal priming job | Internal only |

### Preload — Deal-Scoped Triggers

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/preload/deal` | Start configured image priming for a batch of deals or countries | Internal only |
| `POST` | `/v1/preload/deal/{dealUuid}` | Start image priming for a single deal by UUID | Internal only |
| `POST` | `/v1/preload/country/{cc}` | Start image priming for all scheduled deals in a given country | Internal only |

### Preload — Image-Scoped Trigger

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/preload/image/{client}/{sha}/{rootName}` | Start priming of all transformation variants for a specific image | Internal only |

### Image Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/images` | Delete an image from S3, GIMS nginx caches, and Akamai storage | LDAP group header (`x-grpn-groups`) |

### Platform Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Kubernetes readiness and liveness probe | None |
| `GET` | `/grpn/status` | Service status endpoint (disabled per service-portal config) | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on POST endpoints except `/v1/images` which uses `application/x-www-form-urlencoded`
- `x-grpn-username` — optional; passed for audit on image delete operations
- `x-grpn-groups` — optional; used for LDAP-based authorization on image delete

### `POST /v1/preload/deal` — Request body (`MultiDealsRequest`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `countries` | `string[]` | Conditional | 2-letter country codes; at least 1 item if `deals` is absent |
| `deals` | `string (uuid)` | Conditional | Deal UUID(s) to prime; exactly one of `deals` or `countries` must be present |
| `config.dealStatus` | `string` | No | Deal status to query — `launched` or `scheduled` (default: `scheduled`) |
| `config.distroWindowInDays` | `integer` | No | Distribution window in days (default: `1`) |
| `config.hitAkamai` | `boolean` | No | Whether to request images from Akamai CDN |
| `config.hitLocalCaches` | `boolean` | No | Whether to hit GIMS local caches |
| `config.hitOriginalImages` | `boolean` | No | Whether to retrieve the original (un-transformed) image |
| `config.hitProcessedImages` | `boolean` | No | Whether to retrieve transformed image variants |
| `config.skipDistroWindowCheck` | `boolean` | No | Skip the 24-hour distribution window filter |
| `config.skipNonScheduledDeals` | `boolean` | No | Skip deals not in scheduled state |
| `config.transformationCodes` | `string[]` | No | Override list of transformation codes; defaults to configured list |

### Error format

> No evidence found in codebase of a standardized error response body beyond JTier/Dropwizard defaults.

### Pagination

> Not applicable — endpoints trigger asynchronous processing; they do not return paginated result sets.

## Rate Limits

> No rate limiting configured on inbound requests. The service internally limits concurrency of outbound requests to deal-catalog and GIMS via RxJava3 scheduler thread counts (configurable via `rxConfig.schedulers.imageService.threadCount` and `rxConfig.schedulers.dealCatalog.threadCount`).

## Versioning

All endpoints are versioned under the `/v1/` URL path prefix.

## OpenAPI / Schema References

- OpenAPI spec: `doc/swagger/swagger.yaml` (Swagger 2.0)
- JSON service discovery: `doc/service_discovery/resources.json`
- Schema base URL (staging): `http://gims-primer-staging-vip.snc1/swagger`
