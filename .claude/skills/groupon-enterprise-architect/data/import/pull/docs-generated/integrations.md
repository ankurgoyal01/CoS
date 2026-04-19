---
service: "pull"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 0
internal_count: 8
---

# Integrations

## Overview

Pull depends on eight internal Continuum services, all accessed synchronously over REST/HTTPS during each page request. There are no external third-party integrations owned by Pull directly. The `pullApiClientFacade` component encapsulates most outbound HTTP calls, with `pullFeatureFlagClient` and `pullGeoResolver` handling their respective specialist integrations. All integrations are called per-request with no background polling.

## External Dependencies

> No evidence found. Pull does not directly integrate with external third-party systems. All dependencies are internal Continuum services.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| API Proxy | REST/HTTPS | Internal gateway for aggregated API payloads — supplemental deal data and content | `apiProxy` |
| Birdcage | REST/HTTPS | Feature flag and experiment configuration resolution per request | `continuumBirdcageService` |
| GeoPlaces | REST/HTTPS | Geographic and place metadata resolution — determines user division and location context | `continuumGeoPlacesService` |
| Layout Service | REST/HTTPS | Page layout and widget configuration for assembling page structure | `continuumLayoutService` |
| Relevance API | REST/HTTPS | Search and browse relevance data — deal cards, facets, ranking | `continuumRelevanceApi` |
| LPAPI | REST/HTTPS | Landing page metadata and route context for browse/local pages | `continuumLpapiService` |
| UGC | REST/HTTPS | User-generated content — ratings and reviews displayed on listing pages | `continuumUgcService` |
| Wishlist | REST/HTTPS | Wishlist read and write for signed-in users during page render | `continuumWishlistService` |

### API Proxy (`apiProxy`) Detail

- **Protocol**: REST/HTTPS
- **Purpose**: Internal gateway providing aggregated API payloads; Pull calls it to retrieve supplemental deal and content data without direct coupling to downstream data services
- **Client**: `pullApiClientFacade` via `keldor` / `axios`
- **Failure mode**: Page renders with degraded content; missing supplemental data may result in incomplete card sets
- **Circuit breaker**: No evidence found

### Birdcage (`continuumBirdcageService`) Detail

- **Protocol**: REST/HTTPS
- **Purpose**: Provides feature flag assignments and experiment bucket treatments that control rendering branches, UI variants, and feature availability per request
- **Client**: `pullFeatureFlagClient` via `itier-feature-flags 3.2.0`
- **Failure mode**: Service defaults to baseline rendering path without experiment treatment; feature flags fail-open to default values
- **Circuit breaker**: No evidence found

### GeoPlaces (`continuumGeoPlacesService`) Detail

- **Protocol**: REST/HTTPS
- **Purpose**: Resolves user division and location context from request IP/headers; used by `pullGeoResolver` to scope deal inventory to the correct geographic market
- **Client**: `pullGeoResolver`
- **Failure mode**: Falls back to a default or inferred division; geographically scoped listings may show wrong market
- **Circuit breaker**: No evidence found

### Layout Service (`continuumLayoutService`) Detail

- **Protocol**: REST/HTTPS
- **Purpose**: Provides page layout configuration and widget/slot definitions that determine the structure of assembled pages
- **Client**: `pullApiClientFacade`
- **Failure mode**: Page may render without dynamic layout segments or fall back to a static default layout
- **Circuit breaker**: No evidence found

### Relevance API (`continuumRelevanceApi`) Detail

- **Protocol**: REST/HTTPS
- **Purpose**: Primary data source for search and browse flows — provides ranked deal cards, facets, and category listings
- **Client**: `pullSearchBrowseOrchestrator` via `pullApiClientFacade`
- **Failure mode**: Search/browse pages cannot render deal content; likely results in an error or empty state page
- **Circuit breaker**: No evidence found

### LPAPI (`continuumLpapiService`) Detail

- **Protocol**: REST/HTTPS
- **Purpose**: Provides landing page metadata and route context used to resolve browse and local page configurations
- **Client**: `pullApiClientFacade`
- **Failure mode**: Landing page context unavailable; page may fall back to generic listing layout
- **Circuit breaker**: No evidence found

### UGC (`continuumUgcService`) Detail

- **Protocol**: REST/HTTPS
- **Purpose**: Supplies user-generated ratings and reviews displayed alongside deal cards on listing pages
- **Client**: `pullApiClientFacade`
- **Failure mode**: Ratings and reviews are omitted from rendered page; page otherwise renders normally
- **Circuit breaker**: No evidence found

### Wishlist (`continuumWishlistService`) Detail

- **Protocol**: REST/HTTPS
- **Purpose**: Reads wishlist state for authenticated users to render saved/wishlisted indicators on deal cards; also supports wishlist add/remove actions surfaced on listing pages
- **Client**: `pullApiClientFacade`
- **Failure mode**: Wishlist indicators omitted or unavailable; wishlist actions may fail silently for signed-in users
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. Pull is called directly by consumer web browsers and mobile web clients (`continuumPullConsumerClients`) over HTTPS.

## Dependency Health

Pull calls all dependencies synchronously per request. There is no evidence of shared circuit breaker infrastructure in the service-level DSL. Dependency failures result in degraded page renders or error states depending on the criticality of the failing service. `@tanstack/react-query 4.29.12` provides in-process request-scoped caching that may reduce repeated outbound calls within a single render cycle.
