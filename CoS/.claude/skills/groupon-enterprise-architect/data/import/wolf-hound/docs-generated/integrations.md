---
service: "wolf-hound"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 0
internal_count: 8
---

# Integrations

## Overview

Wolfhound Editor UI integrates with eight internal Continuum services, all over synchronous HTTP. There are no external (third-party) dependencies. The `domainServiceAdapters` component wraps each upstream service call, and all outbound HTTP is routed through the shared `outboundHttpClient` for instrumentation and error handling.

## External Dependencies

> No evidence found for any external (third-party) dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Wolfhound API | HTTP | Reads and writes pages, templates, schedules, taxonomies, and reports | `continuumWolfhoundApi` |
| Users API | HTTP | Validates users and manages groups/permissions | `continuumWhUsersApi` |
| LPAPI Service | HTTP | Searches and updates LPAPI rules/pages | `continuumLpapiService` |
| Marketing Editorial Content Service | HTTP | Queries image and tag metadata | `continuumMarketingEditorialContentService` |
| Marketing Deal Service | HTTP | Fetches deal divisions and deal details | `continuumMarketingDealService` |
| Deals Cluster Service | HTTP | Loads cluster rules and top cluster content | `continuumDealsClusterService` |
| Relevance API | HTTP | Queries deal cards and relevance search results | `continuumRelevanceApi` |
| Bhuvan Service | HTTP | Fetches geoplaces division metadata | `continuumBhuvanService` |

### Wolfhound API (`continuumWolfhoundApi`) Detail

- **Protocol**: HTTP
- **Auth**: Session / internal service auth
- **Purpose**: Primary data backend — the BFF delegates all page, template, schedule, taxonomy, and report persistence to this service
- **Failure mode**: Editor operations (create, update, publish) fail with an error response; UI surfaces the error to the content author
- **Circuit breaker**: No evidence found

### Users API (`continuumWhUsersApi`) Detail

- **Protocol**: HTTP
- **Auth**: Session / internal service auth
- **Purpose**: Provides user identity validation and group/permission management used to control editorial access
- **Failure mode**: Authentication and permission checks fail; editors cannot access protected routes
- **Circuit breaker**: No evidence found

### LPAPI Service (`continuumLpapiService`) Detail

- **Protocol**: HTTP
- **Auth**: Internal service auth
- **Purpose**: Enables the editor to search and update landing page API rules and pages
- **Failure mode**: LPAPI-related editor panels return errors; other editor functions remain available
- **Circuit breaker**: No evidence found

### Marketing Editorial Content Service (`continuumMarketingEditorialContentService`) Detail

- **Protocol**: HTTP
- **Auth**: Internal service auth
- **Purpose**: Provides image and tag metadata used when composing editorial pages
- **Failure mode**: Image/tag selection UI degrades; page composition continues with reduced metadata
- **Circuit breaker**: No evidence found

### Marketing Deal Service (`continuumMarketingDealService`) Detail

- **Protocol**: HTTP
- **Auth**: Internal service auth
- **Purpose**: Supplies deal division lists and deal details for editorial page composition
- **Failure mode**: Deal selection panels return errors; editorial pages cannot be associated with deals
- **Circuit breaker**: No evidence found

### Deals Cluster Service (`continuumDealsClusterService`) Detail

- **Protocol**: HTTP
- **Auth**: Internal service auth
- **Purpose**: Loads cluster rules and top cluster content for cluster-driven editorial pages
- **Failure mode**: Cluster panels return errors; non-cluster editorial operations remain available
- **Circuit breaker**: No evidence found

### Relevance API (`continuumRelevanceApi`) Detail

- **Protocol**: HTTP
- **Auth**: Internal service auth
- **Purpose**: Provides deal card data and relevance-ranked search results displayed in the editor
- **Failure mode**: Relevance search panels return errors; editors cannot preview ranked deal content
- **Circuit breaker**: No evidence found

### Bhuvan Service (`continuumBhuvanService`) Detail

- **Protocol**: HTTP
- **Auth**: Internal service auth
- **Purpose**: Supplies geoplaces and division metadata used for location-scoped editorial page targeting
- **Failure mode**: Geoplace/division selectors return errors; location targeting is unavailable
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model.

The Wolfhound Editor UI is accessed by human users (content editors and editorial administrators) via browser. It is not consumed programmatically by other internal services.

## Dependency Health

All upstream dependencies are called via the shared `outboundHttpClient` component, which provides request instrumentation and error handling. No circuit breaker or retry patterns are evidenced in the architecture model. Failure handling is per-request — upstream errors surface as BFF error responses to the frontend.
