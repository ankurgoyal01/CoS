---
service: "contract-data-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [client-id-header]
---

# API Surface

## Overview

Contract Data Service exposes a REST API over HTTP (port 8080). All endpoints produce and consume `application/json`. The API is versioned under `/v1/`. Consumers identify themselves via an optional `CLIENT-ID` request header which is validated by the `cds_clientIdRequestFilter`. The service does not implement OAuth2 or JWT; access control is managed at the network/infrastructure layer.

## Endpoints

### Contract Aggregate

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/contract` | Create a new aggregate contract record (party + terms + invoicing config in one request) | `CLIENT-ID` header (optional) |

### Contract Party

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `PUT` | `/v1/contractParty` | Upsert a contract party record associated with a contract ID | `CLIENT-ID` header (optional) |
| `GET` | `/v1/contractParty/{contractId}` | Retrieve a contract party by its contract ID | `CLIENT-ID` header (optional) |

### Contract Term

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/contractTerm` | Upsert a contract term for a given contract (deduplication by hash) | `CLIENT-ID` header (optional) |
| `GET` | `/v1/contractTerm/{contractTermId}` | Retrieve a contract term by its UUID | `CLIENT-ID` header (optional) |

### Payment Invoicing Configuration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `PUT` | `/v1/paymentInvoicingConfiguration` | Upsert a payment invoicing configuration (partial update semantics) | `CLIENT-ID` header (optional) |
| `GET` | `/v1/paymentInvoicingConfiguration/{externalReferenceId}` | Retrieve a payment invoicing configuration by external reference ID | `CLIENT-ID` header (optional) |

### Backfill

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/v1/backfillDeal/{historicalContractNumber}/{dealUUID}` | Trigger backfill of legacy deal data from DMAPI into CoDS format | `CLIENT-ID` header (optional) |

## Request/Response Patterns

### Common headers

- `CLIENT-ID` (string, optional in schema but validated by filter): Identifies the calling service. Loaded from the `client_id` table in the read-only Postgres replica.
- `Content-Type: application/json` — required for all POST/PUT requests.
- `Accept: application/json` — standard for all requests.

### Error format

Errors are mapped via JAX-RS exception mappers:

- `CodsExceptionMapper` — handles CoDS-specific domain exceptions
- `IllegalArgumentExceptionMapper` — returns 400 Bad Request for invalid arguments
- `NoSuchElementExceptionMapper` — returns 404 Not Found when a requested entity does not exist

Standard HTTP status codes are used. Error responses are JSON bodies produced by the registered exception mappers.

### Pagination

> No evidence found in codebase. No pagination is implemented; endpoints return single entities or bulk results.

## Rate Limits

> No rate limiting configured. Access control is handled at the network layer.

## Versioning

All endpoints are prefixed with `/v1/`. Version is embedded in the URL path. The service currently exposes only `v1` endpoints. The OpenAPI spec version is `1.0.local-SNAPSHOT`.

## OpenAPI / Schema References

The full OpenAPI (Swagger 2.0) specification is available at:
- `doc/swagger/swagger.yaml` — generated Swagger 2.0 spec with all request/response schemas
- `doc/swagger/config.yml` — Swagger UI configuration

Key request schema types (from `doc/swagger/swagger.yaml`):

| Schema | Description |
|--------|-------------|
| `ContractParam` | Aggregate contract creation: requires `contractParty`, `contractTerms[]`, `paymentInvoicingConfigurations[]` |
| `ContractTermParam` | Contract term: requires `externalIds[]`, `hash`, `paymentTerm`, `pricing`, `source` |
| `ContractPartyParam` | Contract party with optional payment schedule (cadence, days) |
| `PaymentConfigurationParam` | Invoicing config: requires `externalKey`; optional `initialPayment`, `installments[]` |
| `AbstractContractTermParam.PricingParam` | Pricing: requires `amounts[]`, `format`, `priceType` |
| `AbstractContractTermParam.AdjustmentsParam` | Payment adjustment: requires `type`; optional `amount`, `currencyCode`, `percentage` |
| `AbstractContractTermParam.TaxParam` | Tax config: optional `exempt`, `location`, `responsibleParty` |
