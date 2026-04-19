---
service: "bots"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth2, api-key]
---

# API Surface

## Overview

The BOTS API (`continuumBotsApi`) is a REST HTTP service built on Dropwizard/JTier. It exposes merchant-scoped resources for booking lifecycle management, campaign and service configuration, availability querying, and related operations. All routes are merchant-scoped under `/merchants/{id}/`. The API is consumed by merchant-facing tooling and internal Groupon systems.

## Endpoints

### Bookings

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/merchants/{id}/bookings` | Create a new booking for a merchant | oauth2 / api-key |
| GET | `/merchants/{id}/bookings` | Search/list bookings for a merchant | oauth2 / api-key |
| PUT | `/merchants/{id}/bookings/{bookingId}/reschedule` | Reschedule an existing booking | oauth2 / api-key |
| PUT | `/merchants/{id}/bookings/{bookingId}/checkin` | Check in a customer against a booking | oauth2 / api-key |
| PUT | `/merchants/{id}/bookings/{bookingId}/cancel` | Cancel a booking | oauth2 / api-key |
| PUT | `/merchants/{id}/bookings/{bookingId}/acknowledge` | Acknowledge a booking | oauth2 / api-key |
| DELETE | `/merchants/{id}/bookings/{bookingId}` | Delete a booking record | oauth2 / api-key |

### Campaigns

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchants/{id}/campaigns` | Retrieve merchant campaign configurations | oauth2 / api-key |
| POST | `/merchants/{id}/campaigns` | Create or update a merchant campaign | oauth2 / api-key |

### Services

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchants/{id}/services` | Retrieve merchant service definitions for bookable deals | oauth2 / api-key |
| POST | `/merchants/{id}/services` | Create or update a merchant service definition | oauth2 / api-key |

### Availability

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchants/{id}/availability` | Query available booking slots for a merchant | oauth2 / api-key |
| POST | `/merchants/{id}/availability` | Define or update availability windows | oauth2 / api-key |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — all request and response bodies
- `Authorization` — bearer token or API key depending on auth mechanism
- `Accept: application/json`

### Error format

Errors follow standard JTier/Dropwizard error responses with an HTTP status code and a JSON body containing `code` and `message` fields. Validation errors return HTTP 422 with field-level detail where applicable.

### Pagination

Search/list endpoints (e.g., `GET /merchants/{id}/bookings`) support pagination via query parameters. Specific parameter names are defined by JTier conventions (`limit`, `offset` or cursor-based depending on endpoint).

## Rate Limits

> No rate limiting configured at the application layer. Traffic shaping is managed by upstream Kubernetes ingress and load-balancer configuration.

## Versioning

No explicit URL versioning (no `/v1/` prefix). The API evolves in place following JTier service conventions. Breaking changes are coordinated with known consumers.

## OpenAPI / Schema References

> No OpenAPI spec file was identified in the repository inventory. Schema definitions are embedded in Jersey resource classes and JTier request/response POJOs. Contact the BOTS team (ssamantara, rdownes, joeliu) for schema details.
