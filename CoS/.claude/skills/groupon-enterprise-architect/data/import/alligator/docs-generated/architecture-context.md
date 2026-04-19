---
service: "alligator"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAlligatorService", "continuumAlligatorRedis"]
---

# Architecture Context

## System Context

Alligator sits within the `continuumSystem` (Continuum Platform) as a card aggregation layer that bridges the Cardatron campaign data store with real-time client requests. It is positioned between downstream card and deal data providers (Cardatron Campaign Service, GAPI API Proxy, Relevance API, Janus, Deal Decoration, Deal Recommendation) and upstream consumers that need assembled card payloads (primarily RAPI). The service relies on a Redis cache (`continuumAlligatorRedis`) to avoid fan-out to upstream services on every request; a scheduled background worker refreshes that cache on a periodic basis.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Alligator Service | `continuumAlligatorService` | Backend Service | Java, Spring Boot | 2.5.14 | Spring Boot card aggregation service that assembles and decorates card payloads for clients |
| Alligator Redis Cache | `continuumAlligatorRedis` | Cache / Database | Redis | — | Redis cache storing card, deck, template, and derived lookup data for request-time assembly |

## Components by Container

### Alligator Service (`continuumAlligatorService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Controllers (`alligator_apiControllers`) | Spring MVC controllers for card, config, cache, status, heartbeat, and debug endpoints | Spring MVC |
| Card Orchestration Service (`cardOrchestrationService`) | Core orchestration in CardatronService and related services for card selection and assembly | Spring Services |
| Source Client Executors (`sourceClientExecutors`) | HTTP client/executor layer for Cardatron, RAPI, GAPI, Janus, recommendations, decoration, user, audience, weather, and taxonomy sources | JTier HTTP Clients / Hystrix |
| Cache and Catalog Access (`cacheAndCatalogAccess`) | Redis cache access and in-memory catalog loaders for decks, templates, cards, and geo polygons | Redis + In-memory Cache |
| Response Decoration and Validation (`responseDecorationAndValidation`) | Validation, filtering, and decoration utilities for card/deal payload shaping | Domain Services / Utils |
| Cache Reload Worker (`cacheReloadWorker`) | Scheduled worker that refreshes cached card/catalog data from the Cardatron Campaign Service | Spring Scheduled Worker |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAlligatorService` | `continuumAlligatorRedis` | Reads and writes cached card/catalog data; performs health checks | Spring Data Redis |
| `continuumAlligatorService` | `continuumTaxonomyService` | Loads taxonomy data used by card processing | HTTP/JSON |
| `continuumAlligatorService` | `apiProxy` | Queries deals via GAPI source | HTTP/JSON |
| `continuumAlligatorService` | `continuumRelevanceApi` | Queries cards/deals via realtime API source | HTTP/JSON |
| `continuumAlligatorService` | `continuumUsersService` | Fetches user account details for request context | HTTP/JSON |
| `continuumAlligatorService` | `continuumAudienceManagementService` | Fetches audience attributes for card eligibility checks | HTTP/JSON |
| `continuumAlligatorService` | `openWeather` | Fetches weather data for weather-aware card selection | HTTP/JSON |
| `continuumAlligatorService` | `externalCardatronCampaignService` | Fetches decks, cards, templates, clients, polygons, and permalinks for cache population | HTTP/JSON |
| `continuumAlligatorService` | `externalRecentlyViewedService` | Requests recently viewed deal impressions for personalization | HTTP/JSON |
| `continuumAlligatorService` | `externalFinchService` | Fetches experiment and config assignments for template/deck bucketing | HTTP/JSON |
| `continuumAlligatorService` | `externalDealDecorationService` | Decorates deals for card payloads | HTTP/JSON |
| `continuumAlligatorService` | `externalDealRecommendationService` | Retrieves recommendation and cross-sell deal sets | HTTP/JSON |
| `continuumAlligatorService` | `externalJanusService` | Retrieves personalized recently-viewed cards | HTTP/JSON |
| `alligator_apiControllers` | `cardOrchestrationService` | Invokes card retrieval and response assembly use cases | direct |
| `cardOrchestrationService` | `sourceClientExecutors` | Dispatches source-specific requests and collects responses | direct |
| `cardOrchestrationService` | `cacheAndCatalogAccess` | Reads cached decks, cards, templates, and geo polygon metadata | direct |
| `cardOrchestrationService` | `responseDecorationAndValidation` | Validates eligibility and decorates cards/deals before response | direct |
| `cacheReloadWorker` | `cacheAndCatalogAccess` | Refreshes all cache entries on schedule | direct |
| `sourceClientExecutors` | `responseDecorationAndValidation` | Passes source payloads for normalization and decoration | direct |

## Architecture Diagram References

- Component view: `components-continuum-alligator-cardOrchestrationService`

> Note: Dynamic views for this service are not yet modeled in the architecture DSL (`views/dynamics.dsl` is currently empty).
