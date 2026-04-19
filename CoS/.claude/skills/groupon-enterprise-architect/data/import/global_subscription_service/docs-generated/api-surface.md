---
service: "global_subscription_service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [cookie, client_id]
---

# API Surface

## Overview

The Global Subscription Service exposes a REST API over HTTP on port 9000. Consumers use it to create, read, update, and remove SMS consents, manage email notification subscription lists, and register or update push notification device tokens. The API is versioned by URL path prefix (`/scs/v1.0/` for consent endpoints) and uses JSON for request and response bodies. An OpenAPI 2.0 (Swagger) specification is maintained at `doc/swagger/swagger.yaml`.

## Endpoints

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Kubernetes readiness/liveness probe | None |

### SMS Consent APIs (`/scs/v1.0/consent`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/scs/v1.0/consent/consent_types` | Retrieve consent types for a country/locale/client | `client_id` query param |
| POST | `/scs/v1.0/consent/consent_types` | Create a new consent type for a locale | `client_id` query param, Cookie |
| GET | `/scs/v1.0/consent/consumer/{consumer_id}` | Get all SMS consents for a consumer UUID | `client_id` query param |
| POST | `/scs/v1.0/consent/consumer/{consumer_id}` | Create SMS consent for a consumer and mobile number | `client_id` query param, Cookie |
| PUT | `/scs/v1.0/consent/consumer/{consumer_id}/consent_type/{taxonomy_uuid}` | Update consent for a consumer's consent type | `client_id` query param, Cookie |
| DELETE | `/scs/v1.0/consent/consumer/{consumer_id}/consent_type/all` | Remove all consents for a consumer | `client_id` query param, Cookie |
| DELETE | `/scs/v1.0/consent/consumer/{consumer_id}/consent_type/{consent_type_uuid}` | Remove a specific consent type for a consumer | `client_id` query param, Cookie |
| GET | `/scs/v1.0/consent/phone/{phone_number}` | Get consents for a phone number (deprecated) | `client_id` query param |
| DELETE | `/scs/v1.0/consent/phone/{phone_number}/consent_type/all` | Remove all consents for a phone number (deprecated) | `client_id` query param, Cookie |
| DELETE | `/scs/v1.0/consent/phone/{phone_number}/consent_type/{taxonomy_uuid}` | Remove a specific consent type for a phone number (deprecated) | `client_id` query param, Cookie |
| DELETE | `/scs/v1.0/consent/phone/-/consent_type/all` | Remove all consents for a phone number (body-based, preferred) | `client_id` query param, Cookie |
| DELETE | `/scs/v1.0/consent/phone/-/consent_type/{taxonomy_uuid}` | Remove a specific consent type for a phone number (body-based) | `client_id` query param, Cookie |

### Subscription List APIs (`/lists`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/lists/{country_code}` | Get subscription lists for a country and list types | None |
| POST | `/lists/list/{country_code}/{list_type}/{list_id}` | Create a subscription list | None |
| PUT | `/lists/list/visible/{country_code}/{list_type}/{list_id}` | Update subscription list visibility | None |

### Push Subscription APIs (`/push-subscription`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/push-subscription/device-token/{deviceToken}` | Get push subscriptions by device token | None |
| GET | `/push-subscription/device/{deviceId}` | Get push subscriptions by device ID | None |
| POST | `/push-subscription/token` | Create push subscription by token | `X-Brand` header |
| DELETE | `/push-subscription/public-id/{publicId}` | Delete push subscription by public ID | None |
| GET | `/push-subscription/replay/{deviceId}` | Replay create subscription event by device ID | None |
| GET | `/push-subscription/tempdevice/{deviceId}` | Get temporary push subscriptions by device ID | None |
| GET | `/push-subscription/division-fill/clientId/{clientId}/device/{deviceId}` | Generate division by device ID | None |
| GET | `/push-subscription/migration/{token}` | Data migration endpoint for push subscriptions | None |

### Push Token APIs (`/push-token`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/push-token/consumer/{consumerId}` | Get push device tokens by consumer UUID | None |
| GET | `/push-token/device-token/{deviceToken}` | Get push device token by token value | None |
| POST | `/push-token/device-token` | Register a new push device token | `X-REMOTE-USER-AGENT`, `X-BRAND`, `X-COUNTRY-CODE` headers |
| PUT | `/push-token/device-token/{deviceToken}` | Update a push device token | `Cookie`, `X-REMOTE-USER-AGENT`, `X-BRAND`, `X-COUNTRY-CODE` headers |
| GET | `/push-token/device-token/{deviceToken}/replay/create` | Replay create token event | None |
| GET | `/push-token/device-token/{deviceToken}/replay/update` | Replay update token event | None |
| GET | `/push-token/device/{deviceId}` | Get push device tokens by device ID | None |
| GET | `/push-token/tempdevice/{deviceId}` | Get temporary push device tokens by device ID | None |

### Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/retry/errors` | Manually trigger retry of failed operations | None |

## Request/Response Patterns

### Common headers
- `Cookie: b=<UUID>` — browser identifier cookie used for consent attribution
- `X-Brand: groupon` — brand context for push token operations
- `X-COUNTRY-CODE: US` — country context for push token operations
- `X-REMOTE-USER-AGENT: dogfood` — user agent classification for push token registration

### Error format
Errors are returned as JSON using the `ErrorResponse` schema. Each response contains an `errorCode` (from the `ErrorCode` enum), an `errorMessage` string, and an optional list of `ErrorDetail` objects. HTTP status codes 400 (bad request), 404 (not found), and 500 (internal error) are used.

### Pagination
> No evidence found in codebase.

## Rate Limits

> No rate limiting configured.

## Versioning

Consent endpoints are versioned via URL path prefix: `/scs/v1.0/`. Push token and push subscription endpoints are unversioned. Phone-number-based consent endpoints that accept phone in the URL path are marked deprecated; the preferred replacement uses phone in the request body (`/scs/v1.0/consent/phone/-/...`).

## OpenAPI / Schema References

OpenAPI 2.0 (Swagger) specification: `doc/swagger/swagger.yaml`

Published at: `https://github.groupondev.com/subscription/global_subscription_service/blob/master/doc/swagger/swagger.yaml`
