---
service: "clo-ita"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 0
internal_count: 6
---

# Integrations

## Overview

`clo-ita` has six internal Continuum platform dependencies and no external (third-party) dependencies. All downstream calls are synchronous HTTPS/JSON requests initiated by incoming user requests. The service uses the itier request module pattern (via `cloProxyAdapters`) to call each downstream service, with `itier-clo-client` wrapping CLO-specific API interactions.

## External Dependencies

> No evidence found. No external (outside Continuum/Groupon) dependencies are defined in the architecture model.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| API Proxy | HTTPS/JSON | Forwards claim, bulk-claim, card enrollment, SMS consent, and related-deals requests to the CLO Backend API | `apiProxy` |
| Marketing Deal Service | HTTPS/JSON | Reads deal details and claim eligibility context for rendering deal claim pages | `continuumMarketingDealService` |
| Users Service | HTTPS/JSON | Reads user profile and consent/enrollment state | `continuumUsersService` |
| Orders Service | HTTPS/JSON | Reads transaction and order summaries for CLO users | `continuumOrdersService` |
| Geo Details Service | HTTPS/JSON | Reads geo details for location-aware CLO experiences | `continuumGeoDetailsService` |
| Deal Catalog Service | HTTPS/JSON | Reads deal catalog metadata for page rendering | `continuumDealCatalogService` |

### API Proxy (`apiProxy`) Detail

- **Protocol**: HTTPS/JSON
- **Purpose**: Acts as the shared gateway to the CLO Backend API. Routes claim, bulk-claims, card_enrollments, consent_sms, and related_deals operations.
- **Auth**: Session-based; user identity passed through from the incoming I-Tier session
- **Failure mode**: CLO claiming and enrollment features are unavailable if the proxy is down
- **Circuit breaker**: No evidence found in architecture model

### Marketing Deal Service (`continuumMarketingDealService`) Detail

- **Protocol**: HTTPS/JSON
- **Purpose**: Supplies deal details and claim eligibility context needed to render the deal claim page
- **Auth**: Internal service-to-service call
- **Failure mode**: Deal claim page cannot be rendered without deal eligibility data
- **Circuit breaker**: No evidence found in architecture model

### Users Service (`continuumUsersService`) Detail

- **Protocol**: HTTPS/JSON
- **Purpose**: Provides user profile data and current consent/enrollment state for the authenticated user
- **Auth**: Internal service-to-service call
- **Failure mode**: Enrollment and consent flows are unavailable if users service is down
- **Circuit breaker**: No evidence found in architecture model

### Orders Service (`continuumOrdersService`) Detail

- **Protocol**: HTTPS/JSON
- **Purpose**: Provides transaction and order summaries for CLO cashback display
- **Auth**: Internal service-to-service call
- **Failure mode**: Transaction summary page is unavailable if orders service is down
- **Circuit breaker**: No evidence found in architecture model

### Geo Details Service (`continuumGeoDetailsService`) Detail

- **Protocol**: HTTPS/JSON
- **Purpose**: Provides location details used in location-aware CLO experiences
- **Auth**: Internal service-to-service call
- **Failure mode**: Location-sensitive experiences degrade gracefully without geo data
- **Circuit breaker**: No evidence found in architecture model

### Deal Catalog Service (`continuumDealCatalogService`) Detail

- **Protocol**: HTTPS/JSON
- **Purpose**: Provides deal catalog metadata required for rendering CLO pages
- **Auth**: Internal service-to-service call
- **Failure mode**: Pages dependent on catalog metadata cannot render fully
- **Circuit breaker**: No evidence found in architecture model

## Consumed By

> Upstream consumers are tracked in the central architecture model. Frontend web and mobile clients initiate HTTP requests to `continuumCloItaService` endpoints.

## Dependency Health

> Operational procedures to be defined by service owner. No health-check, retry, or circuit-breaker patterns are documented in the architecture inventory.
