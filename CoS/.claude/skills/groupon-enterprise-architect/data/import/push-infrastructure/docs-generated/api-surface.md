---
service: "push-infrastructure"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

Push Infrastructure exposes a REST HTTP API (Play Framework routes) consumed by upstream campaign and transactional services within the Continuum platform. The API provides endpoints for message enqueuing, direct send, transactional messaging, event-triggered channel sends, message state queries, error management, template rendering, scheduling, campaign statistics, cache invalidation, and operational dashboard access.

## Endpoints

### Message Ingestion

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/enqueue_user_message` | Enqueue a message for a specific user across one or more channels | Internal |
| POST | `/send/v1/sends` | Direct multi-channel send (v1 contract) | Internal |
| POST | `/transactional/sendmessage` | Send a transactional message (e.g., order confirmation) | Internal |

### Event-Triggered Channel Sends

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/send/push/event_triggered` | Trigger a push notification from an event payload | Internal |
| POST | `/send/email/event_triggered` | Trigger an email from an event payload | Internal |
| POST | `/send/sms/event_triggered` | Trigger an SMS from an event payload | Internal |

### Message State & User Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/messageState` | Query the delivery state of a message | Internal |
| GET | `/userStatus` | Query the messaging status/preferences for a user | Internal |

### Error Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/errors/retry` | Retry failed message deliveries | Internal |
| POST | `/errors/clear` | Clear error records for messages | Internal |

### Template & Rendering

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/render_template` | Render a FreeMarker template against supplied data | Internal |

### Scheduling

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/schedule` | Schedule a message or campaign send for a future time | Internal |

### Campaign Statistics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/campaign/stats` | Retrieve aggregated delivery statistics for a campaign | Internal |

### Cache Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/cache/invalidate` | Invalidate a cached template or rendered result in Redis | Internal |

### Dashboard

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/dashboard/*` | Operational dashboard — delivery metrics, queue depths, error summaries | Internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — all POST request bodies use JSON
- `Accept: application/json` — all responses return JSON

### Error format

> No standardized error schema is documented in the inventory. Error responses follow Play Framework default JSON error format with HTTP status codes (4xx for client errors, 5xx for server errors).

### Pagination

> No evidence of pagination on current endpoints. Campaign stats and dashboard endpoints may return bounded result sets; pagination behavior is not explicitly documented in the inventory.

## Rate Limits

> No rate limiting configured at the API gateway layer. Per-user/channel delivery rate limits are enforced internally via Redis counters during queue processing — not at the HTTP API boundary.

## Versioning

URL path versioning is partially applied: `/send/v1/sends` carries an explicit `v1` segment. Other endpoints do not carry version segments. No formal deprecation policy is documented.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema were found in the repository inventory. Request/response contracts are defined implicitly in Play Framework route and controller files.
