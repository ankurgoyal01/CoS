---
service: "calendar-service"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

Calendar Service exposes a REST API under the `/v1` path prefix. Consumers include booking surfaces, CX tooling, and internal Continuum services. The API is organized into resource groups covering availability queries, availability ingestion, product segments, unit bookings, booking state transitions, merchant/place configuration sync, and CX-facing operations. All endpoints are served by the `continuumCalendarServiceCalSer` container via the `apiResourcesCalSer` component.

## Endpoints

### Availability

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/services/availability` | Query availability windows for one or more services | Internal service auth |
| POST | `/v1/services/{id}/ingest_availability` | Ingest raw availability data for a given service | Internal service auth |

### Product Segments

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/products/segments` | Retrieve product availability segments | Internal service auth |
| POST | `/v1/products/segments` | Create product availability segments | Internal service auth |
| PUT | `/v1/products/segments` | Update product availability segments | Internal service auth |
| DELETE | `/v1/products/segments` | Remove product availability segments | Internal service auth |

### Unit Bookings

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/units/bookings` | List bookings for a unit | Internal service auth |
| POST | `/v1/units/bookings` | Create a new booking for a unit | Internal service auth |
| PUT | `/v1/units/bookings` | Update an existing unit booking | Internal service auth |
| DELETE | `/v1/units/bookings` | Cancel a unit booking | Internal service auth |

### Booking State Transitions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/bookings/{id}/sync` | Synchronize a booking with external systems (EPODS) | Internal service auth |
| POST | `/v1/bookings/{id}/confirm` | Confirm a pending booking | Internal service auth |
| POST | `/v1/bookings/{id}/decline` | Decline a pending booking | Internal service auth |

### Merchant / Place Sync

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/merchants/{id}/places/{id}/sync` | Synchronize place configuration from M3 Place for a given merchant | Internal service auth |

### CX Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST/PUT/DELETE | `/v1/cx/*` | CX-facing booking and availability operations for customer support tooling | Internal service auth |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — all request and response bodies use JSON
- Internal service identity headers as required by JTier service-to-service auth conventions

### Error format

> No evidence found in the federated architecture model. Standard Dropwizard/JTier error envelopes are expected (HTTP status code + JSON error body with message field).

### Pagination

> No evidence found. Pagination details not declared in the architecture model; consult the OpenAPI spec if available.

## Rate Limits

> No rate limiting configured. Calendar Service is an internal service and rate limiting is not declared in the architecture model.

## Versioning

All endpoints are versioned under the `/v1` path prefix. No header- or query-parameter-based versioning is in evidence.

## OpenAPI / Schema References

> No evidence found. No OpenAPI spec path is declared in the federated architecture DSL. Consult the service repository for any `openapi.yaml` or `swagger.json` artifacts.
