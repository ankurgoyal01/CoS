---
service: "sem-blacklist-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [header]
---

# API Surface

## Overview

The SEM Blacklist Service exposes a REST API over HTTP (port 8080) for querying, creating, and deleting denylist entries. The API surfaces two parallel endpoint families — `/denylist` (canonical) and `/blacklist` (legacy alias) — with identical semantics. Consumers are primarily internal SEM systems and tooling that read denylists filtered by client, country, and search engine. Write operations are performed by SEM operations tooling and the Asana task automation endpoint. All requests and responses use `application/json`.

## Endpoints

### Denylist Management (canonical `/denylist` prefix)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/denylist` | Fetch denylist entries filtered by client, country, and optional filters | `X-GRPN-Username` header (optional) |
| `POST` | `/denylist` | Add a single denylist entry | `X-GRPN-Username` header (optional) |
| `DELETE` | `/denylist` | Remove (soft-delete) a single denylist entry | `X-GRPN-Username` header (optional) |
| `GET` | `/denylist/batch` | Fetch denylist entries for multiple countries in one request | `X-GRPN-Username` header (optional) |
| `POST` | `/denylist/batch` | Add multiple denylist entries in one request | `X-GRPN-Username` header (optional) |
| `GET` | `/denylist/{country}/{client}` | Fetch active denylist entries within a date range | `X-GRPN-Username` header (optional) |
| `POST` | `/denylist/process-asana-tasks` | Manually trigger Asana task processing to add/delete denylist terms | None |

### Blacklist Management (legacy `/blacklist` prefix — same semantics)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/blacklist` | Fetch denylist entries (legacy alias) | `X-GRPN-Username` header (optional) |
| `POST` | `/blacklist` | Add a single denylist entry (legacy alias) | `X-GRPN-Username` header (optional) |
| `DELETE` | `/blacklist` | Remove (soft-delete) a single denylist entry (legacy alias) | `X-GRPN-Username` header (optional) |
| `GET` | `/blacklist/batch` | Fetch denylist entries for multiple countries (legacy alias) | `X-GRPN-Username` header (optional) |
| `POST` | `/blacklist/batch` | Add multiple denylist entries (legacy alias) | `X-GRPN-Username` header (optional) |
| `GET` | `/blacklist/{country}/{client}` | Fetch active denylist entries within a date range (legacy alias) | `X-GRPN-Username` header (optional) |

### Health / Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/status` | JTier service status / health check | None |

## Request/Response Patterns

### Common headers

- `X-GRPN-Username` (string, optional): Identifies the caller for audit trail purposes. Used on all write operations (`POST`, `DELETE`) to record which user created or deleted an entry in the `created_by` / `deleted_by` fields.
- `Content-Type: application/json`: Required for all request bodies.
- `Accept: application/json`: Responses are always JSON.

### Query parameters for `GET /denylist` and `GET /blacklist`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `client` | string | yes | Identifies the SEM client segment (e.g., `pla-deal`, `rtc-deal`, `sem-keywords`) |
| `country` | string | yes | ISO country code |
| `program` | string | no | Filters by program (e.g., `rtc`) |
| `channel` | string | no | Filters by channel (e.g., `g1`) |
| `active` | boolean | no | Filter by active status |
| `list` | boolean | no | If `true`, returns a JSON array of only denylist term strings instead of full objects |
| `page` | integer | no | Zero-based page number for pagination |
| `size` | integer | no | Page size for pagination |
| `search_engine` | string | no | Filter by search engine identifier |

### Query parameters for `GET /denylist/{country}/{client}`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_at` | integer (int64) | no | Unix epoch milliseconds for range start |
| `end_at` | integer (int64) | no | Unix epoch milliseconds for range end |

### Request body for `POST` / `DELETE` (single entry)

```json
{
  "entityId": "string",
  "client": "string",
  "searchEngine": "string",
  "countryCode": "string",
  "entityOptionId": "string",
  "brandMerchantId": "string",
  "brandBlacklistType": "string"
}
```

Fields `entityId`, `client`, `searchEngine`, and `countryCode` are required for write operations.

### Error format

> No evidence found in codebase of a standardized error envelope beyond JTier framework defaults.

### Pagination

Offset-based pagination is supported on list endpoints using `page` (zero-based page index) and `size` (number of results per page) query parameters. Results are ordered by `create_at DESC`.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL versioning strategy is in use. The `/denylist` prefix is the canonical path; `/blacklist` is maintained as a legacy alias. Both paths expose identical operations and share the same underlying DAO.

## OpenAPI / Schema References

- OpenAPI (Swagger 2.0) specification: `doc/swagger/swagger.yaml`
- Service discovery resource descriptor: `doc/swagger/swagger.json`
- Service discovery JSON (full parameter detail): `doc/service_discovery/resources.json`
