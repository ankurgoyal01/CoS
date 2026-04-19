---
service: "bookingtool"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, jwt, okta]
---

# API Surface

## Overview

The Booking Tool exposes 84 endpoints via a query-parameter routing scheme: all requests target a base URL with an `?api_screen=` parameter that identifies the operation. This pattern reflects the legacy PHP architecture. Consumers include merchant admin UIs, customer booking UIs, and internal Continuum services. Authentication is session-based for browser flows and JWT-secured for service-to-service calls; admin flows additionally authenticate through Okta.

## Endpoints

### Booking Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `?api_screen=booking` | Create a new customer booking / reservation | Session / JWT |
| GET | `?api_screen=booking` | Retrieve booking details | Session / JWT |
| POST | `?api_screen=bookingCancel` | Cancel an existing booking | Session / JWT |
| POST | `?api_screen=bookingReschedule` | Reschedule an existing booking to a new slot | Session / JWT |
| POST | `?api_screen=bookingCheckIn` | Record check-in for a customer appointment | Session / JWT |

### Availability Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `?api_screen=availability` | Query available time slots for a merchant/deal | Session / JWT |
| POST | `?api_screen=availability` | Create or update availability windows | Session (Merchant) |
| POST | `?api_screen=blockedTime` | Create a blocked-time entry for a merchant | Session (Merchant) |
| GET | `?api_screen=blockedTime` | List blocked-time entries | Session (Merchant) |
| DELETE | `?api_screen=blockedTime` | Remove a blocked-time entry | Session (Merchant) |

### Bank Holidays

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `?api_screen=bankholidays` | Retrieve bank holiday calendar for a locale | Session / JWT |
| POST | `?api_screen=bankholidays` | Add a bank holiday entry | Admin / Okta |

### Access and Consumer Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `?api_screen=consumerAccessRequest` | Submit a consumer access request | Session / JWT |
| GET | `?api_screen=consumerAccessRequest` | List consumer access requests | Admin / Okta |

> The full set of 84 endpoint variants follows the same `?api_screen=` routing pattern. The table above covers the primary operation groups identified in the service inventory.

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST/PUT request bodies
- `Authorization: Bearer <jwt>` — required for service-to-service calls
- `X-Locale: <locale-code>` — identifies the target locale (e.g., `en-GB`, `en-US`, `fr-FR`)

### Error format

> No evidence found in the inventory for a standardized error response envelope. Expected pattern for PHP services: HTTP status code with a JSON body containing `error` and `message` fields.

### Pagination

> No evidence found for a standardized pagination scheme in the inventory.

## Rate Limits

> No rate limiting configured.

## Versioning

The API does not use URL path versioning. All routing is via the `?api_screen=` query parameter. There is no evidence of a versioning strategy in the inventory; breaking changes would be managed at the application level.

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec, proto files, or schema definition files in the repository inventory.
