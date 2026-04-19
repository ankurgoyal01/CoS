---
service: "billing-record-options-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

BROS exposes a REST HTTP API under the base path `/paymentmethods`. Consumers query this API to retrieve a filtered and ranked list of payment methods applicable to a given checkout context. The service is published internally at region-specific VIPs (e.g., `http://global-payments-config-service-us.snc1`) and is not externally exposed to the public internet. The API is documented via an OpenAPI 3.0.3 schema at `doc/openapi.yml`.

## Endpoints

### Payment Methods

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/paymentmethods` | List payment methods filtered by `paymentProviderId`, `amount`, and `userAgent` | API key (header) |
| GET | `/paymentmethods/{countryCode}` | List payment methods for a given ISO 3166-1 alpha-2 country code with optional context filters | API key (header) |
| GET | `/grpn/status` | Service health and version status (JTier standard endpoint) | None |

### Query Parameters — `GET /paymentmethods`

| Parameter | Type | Description |
|-----------|------|-------------|
| `paymentProviderId` | integer (int64) | Filter to a specific payment provider ID |
| `amount` | integer (int64) | Transaction amount (used for installment calculations) |
| `userAgent` | string | User agent string for client type resolution |

### Query Parameters — `GET /paymentmethods/{countryCode}`

| Parameter | Type | Description |
|-----------|------|-------------|
| `countryCode` (path) | string | Country code (ISO 3166-1 alpha-2), e.g., `US`, `GB`, `CA` |
| `amount` | integer (int64) | Transaction amount |
| `userAgent` | string | User agent string for client type resolution |
| `inventoryProductIds` | string | Comma-separated inventory product IDs (include/exclude filter) |
| `inventoryServiceTypes` | string | Comma-separated service types (e.g., `clo`, `coupons`, `getaways`, `goods`, `glive`, `voucher`) |
| `brand` | string | Brand name (e.g., `groupon`, `livingsocial`) |
| `exchange` | boolean | Whether this is an exchange transaction |
| `primaryDealServiceIds` | string | Comma-separated Primary Deal Service (PDS) category IDs |

## Request/Response Patterns

### Common headers

- `apiKey` (header): API client key for authentication
- Standard JTier request headers (`X-REQUEST-ID`, `X-CLIENT-ROLES`, `X-REMOTE-USER-AGENT`) may be processed for client type resolution

### Error format

Standard HTTP status codes are used:
- `200` — Successful response with `PaymentMethodsRepresentation` body
- `400` — Bad Request (invalid parameters)
- `404` — Not Found (no payment methods matched)
- `500` — Internal Server Error

### Response schema: `PaymentMethodsRepresentation`

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | Human-readable description |
| `countryCodes` | string | ISO 3166-1 alpha-2 country code |
| `self` | url | Self-referencing URL of the response |
| `count` | integer | Number of payment methods returned |
| `paymentMethods` | array | List of `PaymentMethod` objects |

### Response schema: `PaymentMethod`

| Field | Type | Description |
|-------|------|-------------|
| `paymentProviderId` | integer (int64) | Unique payment provider identifier |
| `billingRecordType` | string | Type of billing record (e.g., `creditcard`, `directdebit`, `paypal`) |
| `billingRecordVariant` | string | Variant within the billing record type (e.g., `visa`, `mc`, `amex`) |
| `name` | string | Display name of the payment method |
| `countryCode` | string | ISO 3166-1 alpha-2 country code |
| `flowType` | string | Payment flow type: `api`, `api_async`, `api_sync`, or `hpp` |
| `consentForStoring` | enum | Storage consent model: `opt-in`, `opt-out`, or `not-needed` |
| `applications` | array | Active application contexts for this provider |
| `features` | array | Feature flags associated with this payment method |
| `installments` | array | Installment plan options (min basket, max installments, amounts) |
| `schema` | object | JSON schema for card data fields (e.g., CVV requirements) |
| `connectionConfig` | object | Acquirer/HPP connection configuration overrides |
| `importance` | integer | Ranking score for ordering in the checkout UI |
| `currency` | string | Currency code |
| `lastModified` | datetime | Last configuration change timestamp |
| `autoCapture` | boolean | Whether this provider auto-captures funds |

### Pagination

> No evidence found in codebase. The API returns all matching payment methods in a single response.

## Rate Limits

> No rate limiting configured.

## Versioning

The API uses no URL versioning scheme. The current version is `v1.0` as declared in the OpenAPI schema info. All endpoints are served under the root path.

## OpenAPI / Schema References

- OpenAPI 3.0.3 schema: `doc/openapi.yml`
- Internal service registry: `doc/service_discovery/`
- Note: the `openapi.yml` is mirrored from `groupon-payments-sdk/docs/compass-open-api-schema.yml`
