---
service: "payments"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

The Payments Service exposes an HTTP REST API consumed primarily by the Orders Service for payment authorization and capture during the checkout flow, by the API Gateway (Lazlo) for billing and payment operations, and by the Merchant Flutter App for reading payment schedules. The API is an internal-facing service API, not directly exposed to end consumers.

## Endpoints

### Payment Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/payments` | Authorize a new payment (from DSL: `POST /payments (authorize)`) | Internal service auth |
| POST | `/payments/{id}/capture` | Capture a previously authorized payment (from DSL: `POST /payments/{id}/capture`) | Internal service auth |

> The endpoint paths above are inferred from the component-level detail comments in the architecture dynamic views (`dynamic-continuum-payments-service`). The actual endpoint paths should be verified against the service's source code or OpenAPI specification.

### Payment Queries

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/payments/{id}` | Retrieve payment details (implied by merchant app integration) | Internal service auth |
| GET | `/payments/schedules` | Retrieve payment schedules (implied by merchant Flutter app relationship) | Internal service auth |

> No evidence found in codebase for exact query endpoint paths. The above are inferred from the Merchant Flutter App relationship: "Retrieves payment schedules and payment details."

## Request/Response Patterns

### Common headers

> No evidence found in codebase. Standard Groupon internal service headers are expected (correlation-id, authorization, content-type: application/json).

### Error format

> No evidence found in codebase. Likely follows standard Spring Boot error response format with HTTP status codes, error codes, and messages.

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configuration found in architecture model.

## Versioning

> No evidence found in codebase for API versioning strategy.

## OpenAPI / Schema References

> No evidence found in codebase. Service owners should publish an OpenAPI specification for the Payments API.
