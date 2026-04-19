---
service: "subscription-programs-app"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-auth]
---

# API Surface

## Overview

The `selectApi` component (`continuumSubscriptionProgramsApp`) exposes a REST API under two versioned path prefixes — `/select` (v1) and `/select-v2` (v2) — plus administrative paths for support and messaging. Consumers use it to manage Groupon Select memberships, query plans and eligibility, retrieve payment history, and handle KillBill billing callbacks. A separate `/support` and `/message` path serves internal tooling and support agent workflows.

## Endpoints

### Membership Management (v1)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/select/{consumerId}/membership` | Create a new Select membership for a consumer | Internal auth |
| GET | `/select/{consumerId}/membership` | Retrieve current membership status for a consumer | Internal auth |
| PUT | `/select/{consumerId}/membership` | Update membership (e.g., plan change, reactivation trigger) | Internal auth |
| DELETE | `/select/{consumerId}/membership` | Cancel a consumer's Select membership | Internal auth |

### Plan and Eligibility

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/select/plans` | Retrieve available Select subscription plan catalog | Internal auth |
| GET | `/select/{consumerId}/eligible` | Check whether a consumer is eligible for Select | Internal auth |

### Payment History

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/select/{consumerId}/payment-history` | Retrieve billing payment history for a consumer | Internal auth |

### KillBill Webhook Ingestion

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/select/killbill-event` | Receive billing lifecycle events from KillBill (payment success, failure, cancellation) | Internal auth |

### Membership Management (v2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/select-v2/{consumerId}` | Retrieve enhanced v2 membership state (richer status model, reactivation eligibility) | Internal auth |

### Support and Messaging

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/support/{consumerId}/email` | Dispatch a support-triggered email to a consumer via Rocketman | Internal auth |
| POST | `/message/{consumerId}` | Send a programmatic message to a consumer | Internal auth |

## Request/Response Patterns

### Common headers

- Standard Continuum/JTier service-to-service headers are expected (correlation IDs, internal auth tokens).

### Error format

> No evidence found in the architecture inventory. Standard Dropwizard error responses (JSON envelope with error code and message) are expected per JTier conventions.

### Pagination

> Not applicable — payment history and plan list responses are bounded and returned in full.

## Rate Limits

> No rate limiting configured at the service level. Traffic is gated upstream by Continuum API gateway.

## Versioning

Two parallel URL-based API versions are in use:
- **v1**: `/select/{consumerId}/...` — original Select API
- **v2**: `/select-v2/{consumerId}` — enhanced membership state model, introduced to support richer reactivation and status flows

Both versions are actively maintained. See [Flows](flows/index.md) for v1/v2 behavioral differences.

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec committed to the repository. Schema definitions are expressed via Dropwizard resource class contracts.
