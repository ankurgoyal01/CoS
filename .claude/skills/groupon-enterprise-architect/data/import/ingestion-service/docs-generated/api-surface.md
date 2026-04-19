---
service: "ingestion-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, client-id]
---

# API Surface

## Overview

All REST endpoints are served on port `8080` under the base path `/odis/api/v1/`. Every endpoint requires two authentication credentials: the `X-API-KEY` header (API key) and a `client_id` query parameter. The service also exposes a transparent proxy at `/proxy/{path}` for delegating requests to the CAAP API. An admin port (`8081`) serves Dropwizard admin/health endpoints. The OpenAPI specification is available at `doc/swagger/swagger.yaml`.

## Endpoints

### JWK / JWT

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/odis/api/v1/generate/jwkey/keyId/{keyId}` | Generates a JSON Web Key (JWK) for the given key ID | `X-API-KEY` + `client_id` |
| GET | `/odis/api/v1/token/{customerUuid}/keyId/{keyId}` | Generates a signed JWT token for a customer | `X-API-KEY` + `client_id` |

### Memos

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/odis/api/v1/memos` | Retrieves memos for a deal UUID or merchant UUID, optionally filtered by type and domain | `X-API-KEY` + `client_id` |
| GET | `/odis/api/v1/memos/filtered_flags` | Returns memo details where RoR-approved, investigation-in-progress, or informative flags are true | `X-API-KEY` + `client_id` |

### Refunds

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/odis/api/v1/refund` | Processes a refund for an order to a specified destination (Groupon Bucks or original payment) | `X-API-KEY` + `client_id` |
| GET | `/odis/api/v1/merchantApprovedRefunds/triggerJob` | Manually triggers the merchant-approved refunds background job | None documented |

### Salesforce — Account and Opportunity

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/odis/api/v1/salesforce/account` | Retrieves a merchant's Salesforce Account record by merchant UUID | `X-API-KEY` + `client_id` |
| GET | `/odis/api/v1/salesforce/opportunity` | Returns deal opportunity data for a given Salesforce opportunity ID or deal UUID and account ID | `X-API-KEY` + `client_id` |

### Salesforce — Case / Ticket Creation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/odis/api/v1/salesforce/escalate/ticket/create` | Creates a Salesforce case for customer escalation; supports rich context (order, voucher, merchant, deal, customer data) | `X-API-KEY` + `client_id` |
| POST | `/odis/api/v1/salesforce/ticket/create` | Creates a Salesforce ticket from a structured JSON request body | `X-API-KEY` + `client_id` |
| GET | `/odis/api/v1/salesforce/ticket/triggerJob` | Manually triggers retry of a specific failed Salesforce ticket creation job by ID | None documented |

### Salesforce — Messaging Sessions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/odis/api/v1/salesforce/messaging/sessions` | Fetches Salesforce messaging sessions for a customer email and country | None documented |
| PUT | `/odis/api/v1/salesforce/messaging/sessions` | Updates a Salesforce messaging session (description, attachment, transcript) by conversation identifier and country | None documented |

### Salesforce — Surveys

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/odis/api/v1/salesforce/survey/create` | Creates a new Salesforce survey response record | None documented |
| POST | `/odis/api/v1/salesforce/survey/update/{surveyId}` | Updates an existing Salesforce survey response by survey ID | None documented |

### Deals

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/odis/api/v1/{domain}/deals/{dealId}` | Returns deal data from the Lazlo API for a given deal UUID or permalink, by domain | `X-API-KEY` + `client_id` |

### Users

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/odis/api/v1/{domain}/users` | Returns user/customer data by email address and domain | `X-API-KEY` + `client_id` |

### Incentives / Promo Codes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/odis/api/v1/users/{userId}/incentives/best` | Fetches the best available promo code (incentive) for a user in a given domain | `X-API-KEY` + `client_id` |

### Fraud / Signifyd

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/odis/api/v1/signifyd/status` | Returns Signifyd fraud check status for an order ID | `X-API-KEY` + `client_id` |

### Proxy

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/proxy/{path}` | Transparently proxies GET requests to the CAAP API | None documented |
| POST | `/proxy/{path}` | Transparently proxies POST requests to the CAAP API | None documented |

### Health / Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Dropwizard health check (readiness and liveness probe) | None |
| GET | `/grpn/status` | Service version and status endpoint | None |

## Request/Response Patterns

### Common headers
- `X-API-KEY`: API key identifying the calling client (required on all authenticated endpoints)
- `client_id`: Query parameter identifying the calling client (required on all authenticated endpoints)
- `Content-Type: application/json` or `application/x-www-form-urlencoded` depending on endpoint

### Error format
- `401 Unauthorized`: "Client id and secret must be provided in header X-API-KEY and in query parameter client_id respectively"
- `400 Bad Request`: "Invalid/Missing Domain Id", "Invalid/Missing opportunity Id or account Id or deal UUID", etc.
- `500 Internal Server Error`: "Error creating a ticket! It has been queued for a retry." (SF ticket creation failure — triggers job queue)

### Pagination
> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

All endpoints use URL path versioning with the prefix `/odis/api/v1/`. No v2 endpoints are currently defined. The swagger document reflects version `1.42.local-SNAPSHOT`.

## OpenAPI / Schema References

- OpenAPI specification: `doc/swagger/swagger.yaml`
- Service discovery resource manifest: `doc/service_discovery/resources.json`
- Swagger config: `doc/swagger/config.yml`
