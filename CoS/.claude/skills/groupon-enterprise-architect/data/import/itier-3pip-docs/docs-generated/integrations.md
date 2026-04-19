---
service: "itier-3pip-docs"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 4
---

# Integrations

## Overview

`itier-3pip-docs` integrates with four internal Continuum platform services and one external CMS. All integrations are synchronous. The two primary data integrations are `continuumUsersService` (authentication on every API call) and `continuumApiLazloService` (deal enrichment). Partner configuration data is accessed via GraphQL through the PAPI and GAPI backends (represented by the `graphqlGateway` component).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Ghost CMS | HTTP | Renders the developer portal page shell and injects simulator widgets into Ghost-managed pages | no | Not modelled in DSL |

### Ghost CMS Detail

- **Protocol**: HTTP
- **Base URL / SDK**: `@grpn/itier-ghost-client` (^1.1.1); base URL configured via `serviceClient.ghost.baseUrl` in `config/base.cson`
- **Auth**: Cookie-based (`ghost-members-ssr` and `ghost-members-ssr.sig` cookies)
- **Purpose**: The Groupon Developer Portal is hosted on a Groupon-forked Ghost CMS instance. `itier-3pip-docs` injects widget JavaScript into Ghost pages that render the simulator UI. The Ghost integration is optional for local development.
- **Failure mode**: Simulator widgets fail to render; static documentation remains available
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumUsersService` | Cookie / OAuth token | Validates partner/merchant user sessions on every API request; fetches user identity (`userId`) | `continuumUsersService` |
| `continuumApiLazloService` | HTTPS | Loads and enriches deal data by UUID and country code for test-deal setup | `continuumApiLazloService` |
| GraphQL Partner API (PAPI) | GraphQL | Reads and writes onboarding configurations, simulator logs, partner uptime, deal mappings, reviews, purchases (TTD and HBW), and availability trigger | Not modelled as container in local DSL |
| GraphQL Deal API (GAPI) | GraphQL | Reads deal catalog metadata for deal enrichment flows | Not modelled as container in local DSL |

### `continuumUsersService` Detail

- **Protocol**: Cookie / OAuth token (via `itier-user-auth` ^8.1.0)
- **Auth**: Cookie-based Groupon session
- **Purpose**: Every simulator API action calls `getUserValidation()`, which retrieves the authenticated user's ID via `userAuth.getPersonalizedUser()`. Unauthenticated calls return HTTP 401.
- **Failure mode**: All API endpoints return 401; partner is redirected to Groupon login
- **Circuit breaker**: No evidence found in codebase

### `continuumApiLazloService` Detail

- **Protocol**: HTTPS via `@grpn/api-lazlo-client` (^2.1.1)
- **Auth**: Internal service authentication
- **Purpose**: Fetches deal show data (`dealsShow`) for all test deals associated with a partner's onboarding configuration. Used in `GET /api/get-configure-test-deal-config` and `PUT /api/onboarding-configurations/{configurationId}/trigger-availability`.
- **Failure mode**: Test deal setup config returns without enriched deal details; availability trigger may fail
- **Circuit breaker**: No evidence found in codebase

### GraphQL Partner API (PAPI) Detail

- **Protocol**: GraphQL via `@grpn/graphql-papi` (^3.0.0) and `@grpn/graphql` (^3.1.1)
- **Purpose**: Primary backend for all partner onboarding data — onboarding configurations, configuration status updates, reviews, deal mappings, merchant services, simulator logs, uptime metrics, and purchase history
- **Operations used**: `PAPI_onboardingConfigurations`, `PAPI_simulatorLogs`, `PAPI_partnerUptime`, `PAPI_purchases`, `PAPI_units`, `PAPI_partnerMappingSchema`, `PAPI_merchantServices`, `PAPI_reviews`, `PAPI_createReview`, `PAPI_triggerAvailability`, `PAPI_triggerOnboardingConfigurationStatusUpdateEvent`
- **Failure mode**: API actions return HTTP 500 with error message from GraphQL response
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model.

External integration partners access this service directly via browser at `https://developers.groupon.com` (production) and `https://developers-staging.groupon.com` (staging).

## Dependency Health

> No evidence found in codebase of application-level health checks, retry policies, or circuit breakers for downstream dependencies. Dependency failures propagate as HTTP 500 responses to the frontend. Infrastructure-level health is monitored via the Kubernetes liveness/readiness probes managed by the napistrano/Helm deployment.
