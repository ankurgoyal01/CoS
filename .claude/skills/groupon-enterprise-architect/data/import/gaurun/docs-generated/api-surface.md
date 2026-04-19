---
service: "gaurun"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [none-documented]
---

# API Surface

## Overview

Gaurun exposes a synchronous HTTP/JSON API for push notification submission and operational control. Callers POST notification payloads to the push endpoints and receive an immediate `200 OK` once the notification is accepted into the internal queue — actual delivery to APNs/FCM is asynchronous. The API also provides runtime statistics and concurrency configuration endpoints.

## Endpoints

### Push Submission

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/grpn/push` | Accepts Groupon-format push notification payload and enqueues via Kafka | None documented |
| `POST` | `/grpn/pushmerchant` | Accepts merchant-targeted push notification payload | None documented |
| `POST` | `/grpn/push/push/external/queue` | Alias for `/grpn/push` (external queue path) | None documented |
| `POST` | `/grpn/kafka/queue` | Alias for `/grpn/push` (Kafka queue path) | None documented |
| `POST` | `/grpn/retry` | Internal retry endpoint consumed by the Retry Processor to re-enqueue failed notifications | None documented |

### Operations and Observability

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Returns `200 ok` for liveness/readiness probes | None |
| `GET` | `/stat/app` | Returns Gaurun application statistics (queue depth, pusher count, push success/error counts) | None |
| `GET` | `/stat/go` | Returns Go runtime statistics (goroutines, GC, memory) via `golang-stats-api-handler` | None |
| `PUT` | `/config/pushers` | Adjusts `core.pusher_max` at runtime via `?max=N` query parameter | None |

### Optional Frontend

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/payload` | Renders a payload upload form (only active when `core.frontend = true`) | None |

## Request/Response Patterns

### Push request body (`/grpn/push` and aliases)

Gaurun accepts a `GrpnPayload` envelope format used internally at Groupon:

```json
{
  "template": "...",
  "recipients": [
    {
      "to": "device@iphone-consumer",
      "from": "...",
      "keys": {
        "devices": "<device-token>",
        "payload": { "aps": { "alert": { "title": "...", "body": "..." }, "badge": 1 } },
        "data": { "alert": "...", "link": "...", "title": "..." }
      },
      "vctx": {
        "jobType": "APNS",
        "batchId": "...",
        "nid": "...",
        "dryrun": "false"
      }
    }
  ]
}
```

The `to` field determines the routing context (e.g., `iphone-consumer`, `android-fcm-consumer`). The `vctx.jobType` field (`APNS` or Android) determines platform routing.

### Standard push response body

```json
{ "message": "ok" }
```

### `/stat/app` response body

```json
{
  "queue_max": 8192,
  "queue_usage": 9,
  "pusher_max": 16,
  "pusher_count": 0,
  "ios": { "push_success": 2759, "push_error": 10 },
  "android": { "push_success": 2985, "push_error": 35 }
}
```

### Common headers

- `Content-Type: application/json; charset=utf-8` — set on all responses

### Error format

All errors return a JSON body with the same envelope:

```json
{ "message": "<error description>" }
```

HTTP status codes used:
- `200` — request accepted (notification enqueued)
- `400` — malformed body, empty message, invalid platform, empty token
- `405` — wrong HTTP method
- `429` — internal queue is full (`quota-full`); caller should retry

### Pagination

> Not applicable. All endpoints are single-request/response.

## Rate Limits

> No rate limiting configured in Gaurun itself. Queue capacity limits apply: Android and APNS producer queues are each capped at 100,000 in-flight entries. When full, `/grpn/push` returns `429 Too Many Requests`.

## Versioning

No API versioning strategy. All endpoints are fixed paths prefixed with `/grpn/`.

## OpenAPI / Schema References

No OpenAPI spec file found in repository. Endpoint contracts are documented in [SPEC.md](../../import-repos/gaurun/SPEC.md) (upstream Mercari open-source format) and extended by Groupon in `gaurun/groupon.go` (`GrpnPayload` type).
