---
service: "tronicon-ui"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 0
internal_count: 13
---

# Integrations

## Overview

Tronicon UI integrates exclusively with internal Groupon Continuum services — there are no third-party external dependencies. It has 13 internal service integrations: 3 are confirmed active (Alligator Service, Groupon API, Taxonomy Service), and 10 are stub-only integrations present in the architecture model but not confirmed active in the running service. All integrations use HTTP/REST via the `requests` library.

## External Dependencies

> Not applicable. Tronicon UI has no external third-party dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Campaign Service | REST/HTTP (proxy) | Forwards campaign CRUD operations via `/c/` path proxy | `campaignService` |
| Tronicon CMS | REST/HTTP | Reads and writes CMS content entries | `troniconCms` |
| Card UI Preview | REST/HTTP | Renders card preview for operators | `cardUiPreview` |
| Birdcage Experiments | REST/HTTP | A/B testing configuration (stub) | `birdcageExperiments` |
| Alligator Service | REST/HTTP | Queries experiments for A/B test data (active) | `continuumAlligatorService` |
| Geo Taxonomy API | REST/HTTP | Retrieves geographic taxonomy data for geo-polygon targeting (stub) | `geoTaxonomyApi` |
| API Proxy US | REST/HTTP | API proxying for US region (stub) | — |
| API Proxy EMEA | REST/HTTP | API proxying for EMEA region (stub) | — |
| Groupon API | REST/HTTP | Calls Groupon public API for deal and offer data (active) | `continuumGrouponApi` |
| Taxonomy Service | REST/HTTP | Fetches taxonomy categories for campaign classification (active) | `continuumTaxonomyService` |
| Image Service | REST/HTTP | Uploads and retrieves images for cards and CMS content (stub) | `grouponImageService` |
| Brand Service | REST/HTTP | Retrieves brand data for campaign attribution (stub) | `brandService` |
| Gconfig Service | REST/HTTP | Reads remote application configuration values (stub) | `gconfigService` |
| Audience Service | REST/HTTP | Fetches audience segment data for targeting (stub) | `audienceService` |
| Rocketman Render | REST/HTTP | Requests content rendering for campaign display (stub) | `rocketmanRender` |

### Alligator Service Detail (`continuumAlligatorService`)

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Configured via environment variable; called using `requests` library
- **Auth**: Internal service credentials via environment configuration
- **Purpose**: Queries the Alligator experiments service to retrieve A/B test assignments and experiment configuration for campaign features
- **Failure mode**: Feature degradation — A/B experiment data unavailable; default behaviors apply
- **Circuit breaker**: No evidence found

### Groupon API Detail (`continuumGrouponApi`)

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Configured via environment variable; called using `requests` library
- **Auth**: OAuth2 credentials configured via environment
- **Purpose**: Calls the Groupon public API to retrieve deal and offer data relevant to campaign management workflows
- **Failure mode**: Deal/offer data unavailable for campaign association; operators may be unable to complete campaign linking
- **Circuit breaker**: No evidence found

### Taxonomy Service Detail (`continuumTaxonomyService`)

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Configured via environment variable; called using `requests` library
- **Auth**: Internal service credentials via environment configuration
- **Purpose**: Fetches taxonomy category trees for classifying campaigns and cards within the Groupon merchandise hierarchy
- **Failure mode**: Category selection unavailable; operators unable to assign taxonomy to campaigns
- **Circuit breaker**: No evidence found

### Campaign Service Detail (`campaignService`)

- **Protocol**: REST/HTTP (transparent proxy)
- **Base URL / SDK**: All `/c/:path` requests forwarded to Campaign Service
- **Auth**: Session-forwarded; proxy passes through caller credentials
- **Purpose**: Tronicon UI acts as a reverse proxy for campaign CRUD operations, routing `/c/` prefixed paths directly to the Campaign Service without transformation
- **Failure mode**: Campaign operations unavailable; `/c/` routes return errors
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. Tronicon UI is an internal operator tool with no known programmatic API consumers.

## Dependency Health

> No evidence found in codebase for health check endpoints, retry logic, or circuit breaker patterns on any dependencies. Failure handling relies on HTTP error responses surfaced to the operator's browser.
