---
service: "billing-record-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-service-auth]
---

# API Surface

## Overview

Billing Record Service exposes a REST API with two active API generations (v2 and v3) and an internal v3 endpoint. Responses use `application/hal+json` (v2) or plain JSON (v3). The API is consumed by checkout and order services to create, retrieve, authorize, and deactivate purchaser payment records. All endpoints are scoped to a `purchaserId` (UUID) and, on v2, to a `countryCode` path segment. The full OpenAPI definition is available at `docs/swagger/swagger.json`.

## Endpoints

### Home / Discovery

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/billingrecords` | Returns HAL home resource with navigation links | Internal |

### v2 Billing Records (country-scoped)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v2/{countryCode}/users/{purchaserId}/billingrecords` | Lists all billing records for a purchaser, optionally filtered by `application` | Internal |
| POST | `/v2/{countryCode}/users/{purchaserId}/billingrecords` | Creates a new billing record for a purchaser | Internal |
| GET | `/v2/{countryCode}/users/{purchaserId}/billingrecords/active` | Lists only active billing records for a purchaser | Internal |
| GET | `/v2/{countryCode}/users/{purchaserId}/billingrecords/{billingRecordId}` | Retrieves a single billing record by ID | Internal |
| PUT | `/v2/{countryCode}/users/{purchaserId}/billingrecords/{billingRecordId}/authorize` | Transitions a billing record to AUTHORIZED status | Internal |
| PUT | `/v2/{countryCode}/users/{purchaserId}/billingrecords/{billingRecordId}/deactivate` | Deactivates a single billing record | Internal |
| PUT | `/v2/{countryCode}/users/{purchaserId}/billingrecords/{billingRecordId}/refuse` | Transitions a billing record to REFUSED status | Internal |
| PUT | `/v2/{countryCode}/users/{purchaserId}/billingrecords/activate` | Activates all billing records for a purchaser | Internal |
| PUT | `/v2/{countryCode}/users/{purchaserId}/billingrecords/deactivate` | Deactivates all billing records for a purchaser | Internal |
| POST | `/v2/{countryCode}/users/{purchaserId}/billingrecords/oneTimeRecord` | Creates a one-time-use billing record | Internal |
| GET | `/v2/{countryCode}/users/{purchaserId}/billingrecords/orderslegacyid/{ordersLegacyId}` | Looks up a billing record by Orders legacy ID | Internal |
| GET | `/v2/{countryCode}/users/{purchaserId}/billingrecords/validToken` | Validates a token ID for a purchaser | Internal |

### v2 Migration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v2/{countryCode}/users/{purchaserId}/migration` | Migrates billing records from legacy Orders data for a purchaser | Internal |

### v3 Billing Records (country via header)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v3/users/{purchaserId}/billing_records` | Lists all billing records for a purchaser (country from `X-Country-Code` header) | Internal |
| POST | `/v3/users/{purchaserId}/billing_records` | Creates a new billing record (country from `X-Country-Code` header) | Internal |
| PUT | `/v3/users/{purchaserId}/billing_records/{billingRecordId}` | Updates a billing record (country from `X-Country-Code` header) | Internal |
| DELETE | `/v3/users/{purchaserId}/billing_records/{billingRecordId}` | Deletes a billing record (country from `X-Country-Code` header) | Internal |

### v3 Internal (owner-scoped)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v3/{ownerName}/users/{purchaserId}/billing_records` | Internal creation of billing records for a named owner | Internal |

### Braintree Integration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v2/{countryCode}/users/{purchaserId}/billingrecords/{billingRecordId}/braintree/onetimetoken/grubhub` | Generates a Braintree one-time token for Grubhub | Internal |

## Request/Response Patterns

### Common headers

- `X-Country-Code` (string, required on v3 endpoints) — ISO-2 country code replacing the v2 path segment
- `Content-Type: application/json` — required on POST/PUT requests

### Error format

> No evidence found in codebase. Standard Spring MVC error responses are expected.

### Pagination

> No evidence found in codebase. List endpoints return all results for the purchaser without explicit pagination parameters.

## Rate Limits

> No rate limiting configured.

## Versioning

The API uses URL path versioning: `/v2/` for country-scoped HAL+JSON responses and `/v3/` for the newer plain-JSON interface that accepts the country via the `X-Country-Code` header. Both versions are actively served in production.

## OpenAPI / Schema References

Full Swagger 2.0 specification: `docs/swagger/swagger.json` (title: "Billing Record Service", version: "1.1.0-SNAPSHOT").
