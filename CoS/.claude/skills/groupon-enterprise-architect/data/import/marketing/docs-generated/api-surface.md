---
service: "marketing"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["internal-network"]
---

# API Surface

## Overview

The Marketing & Delivery Platform exposes internal APIs consumed by other Continuum Platform services for triggering marketing notifications and campaign operations. Administrators interact with the platform via HTTPS to create and manage campaigns. The Orders Service calls the platform to trigger confirmation notifications after checkout.

> No evidence found in codebase. The following is inferred from architecture DSL relationships and dynamic views.

## Endpoints

### Campaign Management (inferred)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/campaigns` | Create a new marketing campaign | Internal / HTTPS |
| PUT | `/campaigns/{id}` | Update campaign configuration | Internal / HTTPS |
| POST | `/campaigns/{id}/activate` | Activate a campaign for delivery | Internal / HTTPS |
| GET | `/campaigns/{id}` | Retrieve campaign details | Internal / HTTPS |

### Notification Trigger (inferred)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/notifications/trigger` | Trigger marketing notification (e.g., order confirmation) | Internal / JSON/HTTPS |

### Inbox Management (inferred)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/inbox/{userId}` | Retrieve user inbox messages | Internal / HTTPS |
| PUT | `/inbox/{userId}/messages/{messageId}/read` | Mark inbox message as read | Internal / HTTPS |

### Subscriptions (inferred)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/subscriptions/{userId}` | Retrieve user subscription preferences | Internal / HTTPS |
| PUT | `/subscriptions/{userId}` | Update subscription preferences (opt-in/opt-out) | Internal / HTTPS |

## Request/Response Patterns

### Common headers

> No evidence found in codebase.

### Error format

> No evidence found in codebase.

### Pagination

> No evidence found in codebase.

## Rate Limits

No rate limiting configuration found in codebase.

## Versioning

> No evidence found in codebase. API versioning strategy is not discoverable from the architecture DSL.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or schema references are present in the architecture model.
