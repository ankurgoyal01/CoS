---
service: "itier-tpp"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 2
internal_count: 4
---

# Integrations

## Overview

I-Tier TPP integrates with four internal Continuum platform services for partner, deal, and geo data, and with two external booking platform APIs (Booker and Mindbody) for merchant booking lifecycle management. All integrations are synchronous REST calls made via Gofer HTTP clients or platform-specific client libraries. Authentication toward external APIs uses API keys and OAuth credentials stored as Kubernetes secrets.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Booker API | REST | Manages Booker merchant onboarding and deal-to-class mappings | yes | `bookerApi` |
| Mindbody API | REST | Manages Mindbody merchant onboarding and deal-to-service mappings | yes | `mindbodyApi` |

### Booker API Detail

- **Protocol**: REST (HTTPS)
- **Base URL / SDK**: `@grpn/booker-client ^1.3.2`; base URL configured via `serviceClient.booker.baseUrl` in CSON config
- **Auth**: API key (`serviceClient.booker.apiKey`), client ID and secret (`BOOKER_CLIENT_ID`, `BOOKER_CLIENT_SECRET`) — OAuth 2.0 client credentials
- **Purpose**: Create and update Booker merchant configurations; manage deal-to-Booker-class mappings for the `/partnerbooking` routes
- **Failure mode**: Partner booking pages become unavailable for Booker-integrated partners; error propagates to the UI
- **Circuit breaker**: No evidence found

### Mindbody API Detail

- **Protocol**: REST (HTTPS)
- **Base URL / SDK**: `@grpn/mindbody-client ^2.0.0`; base URL configured via `serviceClient.mindbody.baseUrl` in CSON config
- **Auth**: API key (`serviceClient.mindbody.apiKey`); credentials `MINDBODY_USERNAME` and `MINDBODY_PASSWORD` injected from Kubernetes secret `mindbody-auth`
- **Purpose**: Create and update Mindbody merchant configurations; manage deal-to-Mindbody-service mappings for the `/partnerbooking` routes
- **Failure mode**: Partner booking pages become unavailable for Mindbody-integrated partners; error propagates to the UI
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Partner Service (PAPI) | REST | Reads and writes partner configurations, onboarding configurations, and merchant-partner mappings | `continuumPartnerService` |
| API Lazlo (Groupon V2) | REST | Fetches deals and related Groupon entities for display in portal pages | `continuumApiLazloService` |
| Deal Catalog Service | REST | Retrieves deal history for merchant and deal management views | `continuumDealCatalogService` |
| Geo Details Service (V2) | REST | Loads division and location metadata for geographic context in onboarding flows | `continuumGeoDetailsService` |

### Partner Service (PAPI) Detail

- **Protocol**: REST (HTTPS)
- **Base URL / SDK**: `itier-api-proxy-client ^4.1.0`; base URL configured via `serviceClient.partnerService.baseUrl` in CSON config (timeout: 30 s)
- **Auth**: mTLS interceptor; service identity via Hybrid Boundary
- **Purpose**: Central data store for all partner and onboarding configuration; critical to virtually all portal pages
- **Failure mode**: Most portal functionality becomes unavailable; identified as primary bottleneck in OWNERS_MANUAL
- **Circuit breaker**: No evidence found

### API Lazlo / Groupon V2 Detail

- **Protocol**: REST (HTTPS)
- **Base URL / SDK**: `itier-groupon-v2-client ^4.2.2`; base URL via `serviceClient.grouponV2.baseUrl`; client ID per country (`serviceClient.grouponV2.clientId.US`)
- **Auth**: Client ID; mTLS via Hybrid Boundary
- **Purpose**: Fetch deal and entity data from the Groupon V2 API to populate deal-related portal views
- **Failure mode**: Deal-related portal sections return errors or empty state
- **Circuit breaker**: No evidence found

### Deal Catalog Service Detail

- **Protocol**: REST (HTTPS)
- **Base URL / SDK**: `itier-groupon-v2-deals ^2.1.0`; base URL via `serviceClient.dealCatalogService.baseUrl`
- **Auth**: Client ID per country (`serviceClient.dealCatalogService.clientId.US`); mTLS via Hybrid Boundary
- **Purpose**: Retrieve deal history for the merchant management and deal configuration views
- **Failure mode**: Deal history views return errors
- **Circuit breaker**: No evidence found

### Geo Details Service Detail

- **Protocol**: REST (HTTPS)
- **Base URL / SDK**: `itier-geodetails-v2-client ^2.6.3`
- **Auth**: mTLS via Hybrid Boundary
- **Purpose**: Load division and location metadata to support geographic context during onboarding configuration
- **Failure mode**: Geo/division selection in onboarding forms becomes unavailable
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. The portal is used directly by authenticated human users (operations staff and merchant partners) via browser. No machine-to-machine callers of this service are documented.

## Dependency Health

All downstream calls are made synchronously during request handling. The service does not implement circuit breakers or bulkheads. Timeout values are configured per client:

- Partner Service: 30 s timeout (`serviceClient.partnerService.timeout`)
- Localize: 30 s timeout (`serviceClient.localize.timeout`)
- Global defaults: 10 s connect timeout, 10 s read timeout (`serviceClient.globalDefaults`)

Health of dependencies is monitored indirectly via Nagios alerts on response-time and error-rate increases (see [Runbook](runbook.md)).
