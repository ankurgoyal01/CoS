---
service: "jtier-oxygen"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: []
---

# API Surface

## Overview

JTier Oxygen exposes a REST HTTP API on port 8080, documented via Swagger 2.0. The API is organized into five resource groups — broadcasts, greetings, messagebus, redis, and repos — each exercising a distinct JTier building block. Responses are JSON. The API is intended for internal JTier team use and platform testing, not for external consumers.

## Endpoints

### Broadcasts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/broadcasts` | List all registered broadcasts (paginated, optional stats and message details) | None |
| `POST` | `/broadcasts` | Create a new named broadcast with message count and iteration parameters | None |
| `GET` | `/broadcasts/{name}` | Look up a broadcast by name | None |
| `DELETE` | `/broadcasts/{name}` | Delete a broadcast and all its messages (stops if running) | None |
| `GET` | `/broadcasts/{name}/running` | Check whether a broadcast is currently running | None |
| `PUT` | `/broadcasts/{name}/running` | Start or stop a broadcast by setting running state | None |
| `DELETE` | `/broadcasts/{name}/running` | Stop a running broadcast | None |
| `GET` | `/broadcasts/{name}/stats` | Retrieve throughput statistics for a broadcast (MPS, send count, elapsed time) | None |

### Greetings

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/greetings` | Set (create or update) a greeting for a given name, backed by Postgres | None |
| `GET` | `/greetings/{name}` | Retrieve a greeting by name from Postgres | None |

### MessageBus

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/messagebus/consume` | Consume one message from the default MBus destination and return its payload | None |
| `GET` | `/messagebus/mass-consume/{count}` | Consume `count` messages and return timing statistics | None |
| `POST` | `/messagebus/mass-publish/{count}` | Publish `count` messages and return timing statistics | None |
| `POST` | `/messagebus/mass-roundtrip/{count}/{size}` | Publish and consume `count` messages each of `size` bytes; returns roundtrip stats | None |
| `GET` | `/messagebus/send-safe/{text}` | Publish a single text message to MBus and return the sent message record | None |

### Redis

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/redis` | Store a key-value pair in Redis (with optional TTL in milliseconds) | None |
| `GET` | `/redis/{key}` | Retrieve a value from Redis by key | None |

### Repos

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/repos/{team}/{repo}` | Look up GitHub Enterprise star count for the specified team/repo | None |

### Proxy

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/proxy/{url}` | Forward an HTTP GET to the specified URL and return status, headers, and body | None |

### Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/status` | JTier standard health/status endpoint — returns `commitId` | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST/PUT request bodies
- `Accept: application/json` — all endpoints produce JSON

### Error format

Standard HTTP status codes with JSON bodies. Notable status codes:
- `201` — broadcast created successfully
- `204` — delete or stop operation completed, no response body
- `404` — named resource not found
- `409` — broadcast name conflict (already exists)

### Pagination

The `GET /broadcasts` endpoint returns a `PaginatedBroadcastList` with:
- `items` — page of broadcast records
- `nextResult` — ID to pass as the `start` query parameter on the next page call
- `limit` — query parameter to control page size

## Rate Limits

No rate limiting configured.

## Versioning

No URL-based or header-based API versioning. The API is unversioned; breaking changes are managed via the JTier release process.

## OpenAPI / Schema References

- Swagger 2.0 spec: `doc/swagger/swagger.yaml` in the source repository
- Live spec (staging): `http://jtier-oxygen1-staging.snc1:8080/swagger.yaml`
- Swagger UI (staging): `http://jtier-oxygen1-staging.snc1:8080/swagger`
- Service Portal schema: `https://services.groupondev.com/services/jtier-oxygen/open_api_schemas/latest`
