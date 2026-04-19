---
service: "alligator"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 7
internal_count: 6
---

# Integrations

## Overview

Alligator integrates with 13 downstream services: 6 are registered in the central Continuum architecture model and 7 are external dependencies referenced only as stubs in the architecture DSL. All outbound calls are HTTP/JSON and wrapped in Hystrix circuit-breaker commands. Each service executor family includes a `NoOp` fallback implementation that activates on failure, allowing partial responses rather than total failures. The service is consumed by RAPI and other Continuum platform clients that need assembled card data.

## External Dependencies

### Services in the central architecture model

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Taxonomy Service | REST | Loads taxonomy data used during card processing | yes | `continuumTaxonomyService` |
| API Proxy (GAPI) | REST | Queries deals via the GAPI deal data source | yes | `apiProxy` |
| Relevance API | REST | Queries cards and deals via the realtime API source | yes | `continuumRelevanceApi` |
| Users Service | REST | Fetches user account details for request context | yes | `continuumUsersService` |
| Audience Management Service | REST | Fetches audience segment attributes for eligibility filtering | yes | `continuumAudienceManagementService` |
| OpenWeather | REST | Fetches weather data for weather-aware card selection | no | `openWeather` |

### Services referenced as stubs (not in central model)

| System | Protocol | Purpose | Critical |
|--------|----------|---------|----------|
| Cardatron Campaign Service | REST | Fetches decks, cards, templates, clients, geo polygons, and permalinks for Redis cache population | yes |
| Recently Viewed Service | REST | Requests recently viewed deal impressions for personalization | no |
| Finch (Experiment/Config) Service | Finch SDK | Fetches experiment and config assignments for template and deck bucketing | yes |
| Deal Decoration Service | REST | Applies real-time decoration to deal data embedded in card payloads | yes |
| Deal Recommendation Service | REST | Retrieves recommendation and cross-sell deal sets for card responses | no |
| Janus Service | REST | Retrieves personalized recently-viewed cards | no |
| Watson KV | REST/SDK | Key-value store referenced in `.service.yml` dependencies | no |

### Cardatron Campaign Service Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: Configured via `httpClientConfiguration` / `CardatronServiceConfiguration`; uses parallel paginated supplier pattern (`ParallelPaginator`) for bulk fetching
- **Auth**: Internal network; no explicit token discovered
- **Purpose**: Primary source of truth for all deck, card, template, client, geo polygon, and permalink definitions. Data is fetched in bulk and stored in `continuumAlligatorRedis` by the `cacheReloadWorker`
- **Failure mode**: Cache serves stale data until next successful reload; responses degrade if cache is empty
- **Circuit breaker**: Yes (Hystrix)

### Finch (Experiment/Config) Service Detail

- **Protocol**: Finch SDK (`com.groupon.optimize:finch:3.6.1`)
- **Base URL / SDK**: Maven dependency `com.groupon.optimize:finch`; accessed via `FinchClient` / `FinchServiceConfiguration`
- **Auth**: Internal
- **Purpose**: Retrieves experiment and deck-template bucketing assignments to determine which templates and cards to serve to a given user or visitor for a given deck
- **Failure mode**: Falls back to default template/deck assignments
- **Circuit breaker**: Yes (Hystrix)

### Audience Management Service Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: `AudienceServiceClient` / `AudienceServiceConfiguration`; Hystrix-wrapped executor
- **Auth**: Internal network; `clientId` configured per environment
- **Purpose**: Fetches audience segment attributes for a visitor/consumer UUID, used to filter card eligibility before assembling the response
- **Failure mode**: `NoOpAudienceServiceExecutor` no-op fallback; eligibility filtering is skipped
- **Circuit breaker**: Yes (Hystrix via `AudienceServiceHystrixCommand`)

### Deal Decoration Service Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: `DealDecorationServiceClient` / `DealDecorationServiceConfiguration`
- **Auth**: Internal network
- **Purpose**: Applies real-time decoration (e.g., pricing, availability enrichment) to deal data embedded in card payloads
- **Failure mode**: `NoOpDealDecorationServiceExecutor`; undecorated deal data is returned in cards
- **Circuit breaker**: Yes (Hystrix via `DealDecorationHystrixCommand`)

### Deal Recommendation Service Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: `DealRecommendationServiceClient` / `DealRecommendationServiceConfiguration`
- **Auth**: Internal network
- **Purpose**: Retrieves recommendation and cross-sell deal sets for inclusion as additional cards in the assembled response
- **Failure mode**: `NoOpDealRecommendationServiceExecutor`; recommendation cards are omitted from response
- **Circuit breaker**: Yes (Hystrix via `DealRecommendationHystrixCommand`)

### OpenWeather Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: HTTP client configured via `httpClientConfiguration`
- **Auth**: API key (secret; not documented here)
- **Purpose**: Fetches current weather data for geographic coordinates to enable weather-aware card filtering and selection
- **Failure mode**: Cards are served without weather filtering
- **Circuit breaker**: Yes (Hystrix)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Taxonomy Service | REST | Taxonomy data loading for card processing logic | `continuumTaxonomyService` |
| API Proxy (GAPI) | REST | Deal queries via the GAPI deal data source | `apiProxy` |
| Relevance API | REST | Realtime card and deal queries | `continuumRelevanceApi` |
| Users Service | REST | User account detail lookups for request context | `continuumUsersService` |
| Audience Management Service | REST | Audience attribute lookups for eligibility filtering | `continuumAudienceManagementService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The primary known consumer is the RAPI (Relevance API) realtime service; this service was built specifically to support RAPI's real-time card serving needs. Other Continuum platform clients that require assembled Cardatron card payloads may also call this service.

## Dependency Health

All outbound HTTP calls are wrapped in Hystrix circuit breakers with per-service executor and command classes. Each service executor family includes a `NoOp` fallback that activates on timeout or circuit-open, allowing partial responses:

| Dependency | Fallback | Circuit Breaker Class |
|------------|----------|-----------------------|
| Cardatron Campaign Service | Stale Redis cache | HystrixCommand per executor |
| Finch Service | Default template bucketing | HystrixCommand per executor |
| Audience Management Service | `NoOpAudienceServiceExecutor` | `AudienceServiceHystrixCommand` |
| Deal Decoration Service | `NoOpDealDecorationServiceExecutor` | `DealDecorationHystrixCommand` |
| Deal Recommendation Service | `NoOpDealRecommendationServiceExecutor` | `DealRecommendationHystrixCommand` |
| Janus Service | `NoOpJanusServiceExecutor` | `JanusHystrixCommand` |
| GAPI / API Proxy | `NoOpGapiServiceExecutor` | `GapiHystrixCommand` |

HTTP client configuration (timeouts, thread pool sizes) is managed per service via `HttpClientConfiguration` beans loaded from environment-specific YAML application config files.
