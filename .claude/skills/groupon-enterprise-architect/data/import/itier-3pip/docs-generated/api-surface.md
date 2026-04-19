---
service: "itier-3pip"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

itier-3pip exposes an HTTP API via Express that serves provider-specific booking iframe UIs and handles the booking, checkout, and redemption lifecycle. Routes are segmented by provider (viator, peek, amc, vivid, grubhub, mindbody, hbw) and by flow stage (booking, checkout, redemption). The service is designed to be embedded as an iframe inside Groupon deal pages and is consumed by Groupon consumers via browser.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Service liveness health check | None |

### Viator

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/viator/booking` | Renders Viator booking availability and selection UI | Session |
| POST | `/viator/checkout` | Submits Viator booking checkout | Session |
| GET | `/viator/redemption` | Renders Viator redemption/confirmation UI | Session |

### Peek

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/peek/booking` | Renders Peek availability and booking UI | Session |
| POST | `/peek/checkout` | Submits Peek booking checkout | Session |
| GET | `/peek/redemption` | Renders Peek redemption/confirmation UI | Session |

### AMC

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/amc/booking` | Renders AMC ticket selection UI | Session |
| POST | `/amc/checkout` | Submits AMC booking checkout | Session |
| GET | `/amc/redemption` | Renders AMC redemption/confirmation UI | Session |

### Vivid

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/vivid/booking` | Renders Vivid event/ticket selection UI | Session |
| POST | `/vivid/checkout` | Submits Vivid booking checkout | Session |
| GET | `/vivid/redemption` | Renders Vivid redemption/confirmation UI | Session |

### Grubhub

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grubhub/booking` | Renders Grubhub menu and order UI | Session |
| POST | `/grubhub/checkout` | Submits Grubhub food order checkout | Session |
| GET | `/grubhub/redemption` | Renders Grubhub order confirmation UI | Session |

### Mindbody

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/mindbody/booking` | Renders Mindbody class/appointment booking UI | Session |
| POST | `/mindbody/checkout` | Submits Mindbody booking checkout | Session |
| GET | `/mindbody/redemption` | Renders Mindbody redemption/confirmation UI | Session |

### HBW

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/hbw/booking` | Renders HBW experience booking UI | Session |
| POST | `/hbw/checkout` | Submits HBW booking checkout | Session |
| GET | `/hbw/redemption` | Renders HBW redemption/confirmation UI | Session |

## Request/Response Patterns

### Common headers

- `Cookie` — session cookie required for authenticated booking flows
- `Content-Type: application/json` — for POST checkout requests
- `Accept: text/html` — for GET page renders (server-side rendered Preact UI)

### Error format

> No evidence found in the architecture model for a standardized error response schema. Standard HTTP status codes (4xx/5xx) are expected per Express conventions.

### Pagination

> Not applicable — booking and redemption flows are single-record operations, not paginated lists.

## Rate Limits

> No rate limiting configured at the service level. Rate limiting, if any, is managed at the Kubernetes ingress or upstream Akamai CDN layer.

## Versioning

Routes are not versioned via URL path. Provider-specific routes are segmented by provider name prefix. API evolution is managed through backward-compatible changes and coordinated deployments.

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec or schema definition file in the architecture model. Endpoint contracts are defined implicitly by the Express route handlers and provider client libraries (`itier-tpis-client` 1.36.1, `itier-groupon-v2-client` 4.2.2).
