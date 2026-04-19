---
service: "grouponlive-inventory-service-jtier"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

The service integrates with four external third-party ticketing partner APIs and one internal Groupon service. All outbound HTTP calls are made via Retrofit2 clients configured in `RetrofitClients`. Partner API credentials are injected from secrets at runtime. The internal dependency is the `glive-inventory-rails` service, which receives callbacks for customer reservation updates and event data synchronization.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Provenue API | REST/HTTPS | Seat reservations, purchases, event availability, patron lookup, OAuth token generation | Yes | `provenueApi_34fcfd` |
| Telecharge API | REST/HTTPS | Broadway show details, performance availability, and order creation | Yes | `telechargeApi_18e9fb` |
| AXS API | REST/HTTPS | Venue ticketing data retrieval | No (partial implementation) | Not in federated model |
| Ticketmaster API | REST/HTTPS | Event ticketing data retrieval | No (partial implementation) | Not in federated model |

### Provenue API Detail

- **Protocol**: HTTPS/JSON via Retrofit2
- **Base URL (staging)**: `https://sandbox.pvapi.provenue.com/`
- **Base URL (production)**: `https://prod.pvapi.provenue.com/`
- **Auth**: OAuth2 — service calls `POST /v2/oauth2/accessToken` to obtain a bearer token; tokens are cached in Redis via `ProvenueTokenRepository`
- **Purpose**: Full reservation and purchase flow for Provenue-managed venues. Operations include: ping health check, cart lock (reservation), cart delete (cancel reservation), patron lookup by email, cart checkout (purchase), event availability check, and event detail retrieval.
- **Key endpoints called**: `GET /v2/test/ping`, `POST /v2/oauth2/accessToken`, `POST /v2/carts/lock`, `DELETE /v2/carts/{cartId}`, `GET /v2/patrons`, `POST /v2/carts/{cartId}/checkout`, `GET /v2/availability/events/{eventId}`, `GET /v2/events/{eventId}`
- **Failure mode**: An `ExternalPartnerException` is raised; errors are logged and may trigger an alert to `glive-inventory-rails`
- **Circuit breaker**: No evidence found in codebase

### Telecharge API Detail

- **Protocol**: HTTPS/XML-over-REST via Retrofit2 (Broadway Inbound WS REST service)
- **Base URL (staging)**: `https://eapiqa.dqbroadwayinbound.com/BIWSRest.svc/`
- **Base URL (production)**: `https://eapi.broadwayinbound.com/BIWSRest.svc/`
- **Auth**: Username/password credentials per vendor type (`TC_NON_FIT_USER_NAME`, `TC_NON_FIT_PASSWORD`, `TC_FIT_USER_NAME`, `TC_FIT_PASSWORD`) injected as secrets
- **Purpose**: Broadway show detail retrieval, performance price and availability lookup, and new order creation for Telecharge-managed shows
- **Key endpoints called**: `POST ShowDetails`, `POST PerformancesPOHPricesAvailability`, `POST NewOrder`
- **Failure mode**: `ExternalPartnerException` raised; error logged with partner error message
- **Circuit breaker**: No evidence found in codebase

### AXS API Detail

- **Protocol**: HTTPS via Retrofit2
- **Base URL (staging)**: `https://app.axs.com/`
- **Base URL (production)**: `https://api.veritix.com/`
- **Auth**: API key (`AX_API_KEY`), client ID (`AX_CLIENT_ID`), client secret (`AX_CLIENT_SECRET`), mobile password (`AX_MOBILE_PASSWORD`) injected as secrets
- **Purpose**: Venue ticketing data retrieval; implementation is a stub (`getAxsThing` with dynamic URL)
- **Failure mode**: Exception propagated; implementation is partial
- **Circuit breaker**: No evidence found in codebase

### Ticketmaster API Detail

- **Protocol**: HTTPS via Retrofit2
- **Base URL (staging)**: `http://ticketmaster-placeholder.com/`
- **Base URL (production)**: `https://app.ticketmaster.com/`
- **Auth**: API key (`TM_API_KEY`), secret (`TM_SECRET`) injected as secrets
- **Purpose**: Event ticketing data retrieval; implementation is a stub (`getTMthing` with dynamic URL)
- **Failure mode**: Exception propagated; implementation is partial
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| glive-inventory-rails | REST/HTTP (Retrofit2) | Receives callbacks for customer reservation updates and product event data synchronization; receives third-party purchase error alerts | Not in federated model (configured via `gliveInventoryRails` Retrofit client) |

### glive-inventory-rails Detail

- **Protocol**: Internal HTTP (no TLS on cluster)
- **Base URL (staging)**: `http://grouponlive-inventory-service.staging.service/`
- **Base URL (production)**: `http://grouponlive-inventory-service.production.service/`
- **Purpose**: After a reservation is created, the service calls `PUT /v1/customers/{customerUuid}/reservation` to update the customer's reservation state in the Rails system. After events are updated, calls `PUT v1/products/{productUuid}/events`. Also calls `PUT /alerts/splunk/third_party_purchase_error` when a purchase to an external partner fails.
- **Failure mode**: HTTP error propagated as service exception; error logged

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Upstream callers are internal Groupon services that consume the reservation and purchase REST API, as well as event and product lookup endpoints. Based on the configuration, the primary consumers are within the Groupon Live commerce checkout flow.

## Dependency Health

- Partner API connectivity is validated on the Provenue side via the `ProvenueVendorSyncJob` which calls `GET /v2/test/ping` periodically.
- No circuit breaker or retry library is explicitly configured in the visible code. Retrofit2 calls fail fast on HTTP errors; exceptions are caught and logged using Steno structured logging.
- Redis connection timeout is set to 2000 ms per the configuration YAML.
- MySQL connections are managed by the JTier DaaS MySQL pool; no explicit pool limits visible in the app config layer.
