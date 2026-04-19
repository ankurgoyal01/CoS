---
service: "replay-tool"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, stomp]
auth_mechanisms: []
---

# API Surface

## Overview

The MBus Replay Tool exposes a REST API under the `/replay` path prefix, served by Spring MVC on port 8086 (default) or 8080 (container/Docker). All endpoints return JSON. The API is used by the embedded browser UI (jQuery-based SPA) and can also be called directly by administrators. There is no authentication middleware configured in the codebase; access is controlled at the network/infrastructure level.

## Endpoints

### Replay Request Lifecycle

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/replay/request` | Submit a new replay load request (loads messages from Boson then optionally executes replay) | None (network-controlled) |
| `GET` | `/replay/requests` | List all replay request batches, sorted by request time descending | None |
| `GET` | `/replay/request/{uuid}` | Get a specific replay request batch by UUID | None |
| `GET` | `/replay/request/{uuid}/messages` | Retrieve paginated message frames for a completed load request | None |
| `POST` | `/replay/request/{uuid}/execute` | Execute replay (publish all or partial set of messages to target destination) | None |
| `GET` | `/replay/request/{uuid}/status` | Get execution status and progress (total/sent counts) for a replay | None |
| `POST` | `/replay/load-messages` | Load intercepted messages directly by ReplayLoadRequest payload; returns UUID | None |
| `GET` | `/replay/load-messages/{uuid}/status` | Poll whether a load operation identified by UUID is complete | None |

### Environment Discovery

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/replay/environments` | Returns the currently configured MBus environment name | None |
| `GET` | `/replay/environment/{env}/destinations` | Lists all queues and topics available in the specified environment | None |

### Operational

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/replay/colo` | Returns the currently configured colo (data center) identifier | None |
| `GET` | `/replay/memory/available` | Returns available JVM heap memory in bytes for capacity monitoring | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all `POST` endpoints
- `Accept: application/json` — all responses are JSON

### POST /replay/request — Request body (`ReplayLoadRequestDto`)

```json
{
  "uuid": "optional-existing-uuid",
  "destination": "jms.queue.example-destination",
  "from": "2026-01-15T10:00:00Z",
  "to": "2026-01-15T11:00:00Z",
  "colo": "snc1",
  "environment": "staging",
  "targetDestination": "jms.queue.target-destination",
  "messageIds": "id1,id2,id3",
  "replayOnComplete": false
}
```

Key fields:
- `destination` — source MBus destination to load messages from
- `from` / `to` — ISO-8601 `ZonedDateTime` range for log file query
- `targetDestination` — destination to publish replayed messages to (may differ from source)
- `messageIds` — optional comma-separated list to filter specific messages
- `replayOnComplete` — if `true`, automatically triggers execution once load finishes

### POST /replay/request/{uuid}/execute — Request body (`PartialExecutionDto`)

Optional body. If provided with `bosonRequestHost` and `bosonRequestUuid`, executes replay only for the identified Boson sub-request (partial replay). If omitted or null, executes all sub-requests in the batch.

### GET /replay/request/{uuid}/messages — Query parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `bosonRequestUuid` | yes | — | UUID of the Boson sub-request whose messages to retrieve |
| `bosonRequestHost` | yes | — | Boson host from which the sub-request was loaded |
| `p` | no | `0` | Page number (zero-based) |
| `perPage` | no | `50` | Messages per page |

### Error format

Spring Boot default error response (JSON). No custom error envelope is configured; HTTP status codes follow standard REST conventions (e.g., 500 for `ReplayException`).

### Pagination

The `/replay/request/{uuid}/messages` endpoint uses offset-based pagination via `p` (page number) and `perPage` query parameters. Page numbering starts at 0.

## Rate Limits

No rate limiting configured.

## Versioning

No URL versioning strategy is applied. The API is an internal operator tool not subject to versioning contracts.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema are present in the repository.
