---
service: "gdpr"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 6
---

# Integrations

## Overview

The GDPR service has no external third-party integrations (beyond SMTP email delivery). All upstream data sources are internal Groupon services, accessed via HTTP REST calls. Authentication for Lazlo API calls is token-based, obtained from `cs-token-service` before each data collection step. Direct service-to-service calls for subscriptions, UGC, place details, and consumer addresses use API key or unauthenticated HTTP depending on the endpoint.

## External Dependencies

> No evidence found in codebase. No third-party external system integrations exist. SMTP email delivery uses an internally configured mail relay; no external mail provider credentials are referenced.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `cs-token-service` | REST (HTTP POST) | Issues scoped access tokens used to authenticate calls to the Lazlo API | `tokenService_9f1c2a` (stub) |
| `api-lazlo` | REST (HTTP GET) | Provides consumer orders, preferences, user profile, Groupon Bucks, and SMS consent data | `lazloService_c7b4e1` (stub) |
| `global-subscription-service` | REST (HTTP GET) | Provides consumer subscription records (active, inactive, ineligible) across division, channel, notification, and coupon-merchant list types | `subscriptionService_a2f7c0` (stub) |
| `ugc-api-jtier` | REST (HTTP GET) | Provides paginated user-generated reviews authored by the consumer | `ugcService_31a0e8` (stub) |
| `m3-placeread` | REST (HTTP GET) | Provides place/merchant name and city to enrich review records | `placeService_6b9d42` (stub) |
| `consumer-data-service` | REST (HTTP GET) | Provides consumer profile address/location data | `continuumConsumerDataService` |

### `cs-token-service` Detail

- **Protocol**: HTTP POST
- **Base URL / SDK**: `http://{token_service.host}/api/v1/{country}/token` — host configured in `config/config.toml` under `[token_service]`
- **Auth**: API key passed via `X-API-KEY` header; `client_id` passed in form body
- **Purpose**: Obtains a scoped bearer token (`X-CS-Auth-Token`) for each category of Lazlo API call (e.g., `get_orders`, `users_show`, `get_bucks`, `get_scs_consents`)
- **Failure mode**: Token fetch failure causes the export to abort with an error returned to the agent
- **Circuit breaker**: No evidence found in codebase

### `api-lazlo` Detail

- **Protocol**: HTTP GET
- **Base URL / SDK**: `http://{lazlo.host}/api/mobile/{country}/...` — host configured in `config/config.toml` under `[lazlo]`
- **Auth**: `Authorization: X-CS-Auth-Token {token}` header; token obtained from `cs-token-service` before each call
- **Purpose**: Fetches orders (`/users/{uuid}/orders`), preferences (`/consumers/{uuid}/v2/preferences`), user profile (`/users/{uuid}`), Groupon Bucks (`/users/{uuid}/bucks`), and SMS consent (`/scs/users/{uuid}/consent`)
- **Failure mode**: HTTP error or bad request causes export to abort with error returned to the agent
- **Circuit breaker**: No evidence found in codebase

### `global-subscription-service` Detail

- **Protocol**: HTTP GET
- **Base URL / SDK**: `http://{subscription_service.host}/v2/subscriptions/user/{uuid}` — host configured in `config/config.toml` under `[subscription_service]`
- **Auth**: Unauthenticated (no auth headers observed in `subscriptions.go`)
- **Purpose**: Fetches all subscription records for the consumer including inactive and ineligible entries, filtered by list types: `division`, `channel`, `notification`, `coupon_merchant`
- **Failure mode**: Error causes export to abort; Go `panic` occurs on JSON unmarshalling failure (no graceful recovery)
- **Circuit breaker**: No evidence found in codebase

### `ugc-api-jtier` Detail

- **Protocol**: HTTP GET
- **Base URL / SDK**: `http://{ugc.host}/v1.0/users/{uuid}/reviews` — host configured in `config/config.toml` under `[ugc]`
- **Auth**: Unauthenticated
- **Purpose**: Fetches paginated consumer reviews (page size 50), sorted by time
- **Failure mode**: Error causes export to abort
- **Circuit breaker**: No evidence found in codebase

### `m3-placeread` Detail

- **Protocol**: HTTP GET
- **Base URL / SDK**: `http://{ugc.place_service_host}/placereadservice/v3.0/places/{uuid}` — host configured in `config/config.toml` under `[ugc]` as `place_service_host`
- **Auth**: `client_id` query parameter configured via `ugc.place_service_client_id`
- **Purpose**: Resolves place UUID from a review record to a merchant name and city for display in the Reviews CSV export
- **Failure mode**: Error causes export to abort; custom JSON unmarshalling handles both object and array response shapes
- **Circuit breaker**: No evidence found in codebase

### `consumer-data-service` Detail

- **Protocol**: HTTP GET
- **Base URL / SDK**: `http://{consumer_data_service.host}/v1/consumers/{uuid}/locations` — host configured in `config/config.toml` under `[consumer_data_service]`
- **Auth**: `X-API-KEY` header set with API key from configuration
- **Purpose**: Fetches profile-level location/address records for the consumer (distinct from shipping addresses held in Lazlo)
- **Failure mode**: Error causes export to abort
- **Circuit breaker**: No evidence found in codebase

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Application Operations agents | HTTP (browser) | Trigger GDPR data export requests via the web UI |
| CLI operators | CLI (binary flags) | Trigger GDPR data export requests from the command line |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

No circuit breakers, retry logic, or health-check polling of dependencies is implemented. All downstream calls use a shared HTTP client with TLS verification disabled (`InsecureSkipVerify: true`). Failures in any dependency cause the entire export to fail and return an HTTP 500 to the agent. No fallback or partial-export behaviour is implemented.
