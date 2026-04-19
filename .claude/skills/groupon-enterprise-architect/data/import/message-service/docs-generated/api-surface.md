---
service: "message-service"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

The CRM Message Service exposes a REST HTTP API under the `/api` prefix and a UI application at `/campaign/*`. Consumers use the API to retrieve eligible messages for a user, record interaction events, manage campaigns, and perform operational tasks. The admin UI provides campaign managers with a browser-based interface backed by the same domain logic.

## Endpoints

### Message Delivery

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/getmessages` | Retrieve eligible banner/notification messages for a user (web/mobile channel) | Session |
| GET | `/api/getemailmessages` | Retrieve eligible messages for the email channel | Session |

### Event Tracking

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/messageevent` | Record a user interaction event (view, click, dismiss) against a message | Session |

### Campaign Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `/api/campaign/:id` | Retrieve or update a campaign by ID | Session |
| POST | `/api/message/add` | Create a new message/campaign entry | Session |
| GET/POST | `/api/campaignaudience` | Read or assign audience to a campaign | Session |

### Operational

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/bigtable/scale` | Trigger Bigtable read/write capacity scaling | Session |
| GET | `/heartbeat.txt` | Health check endpoint — returns service liveness status | None |

### Admin UI

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/campaign/*` | Serves the React/Ant Design campaign management single-page application | Session |

## Request/Response Patterns

### Common headers

- Standard HTTP headers for content negotiation (`Content-Type: application/json`)
- Session/auth headers as required by the Continuum platform auth layer

### Error format

> No evidence found in the architecture inventory. Standard Play Framework error responses apply (HTTP status codes with JSON body).

### Pagination

> No evidence found in the architecture inventory.

## Rate Limits

> No rate limiting configured.

## Versioning

All endpoints use unversioned URL paths. No API versioning strategy is documented in the architecture inventory.

## OpenAPI / Schema References

> No evidence found in the architecture inventory. No OpenAPI spec or schema files are referenced.
