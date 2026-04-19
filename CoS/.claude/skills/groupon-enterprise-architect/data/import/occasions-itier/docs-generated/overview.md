---
service: "occasions-itier"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Commerce / Merchandising / Deals Discovery"
platform: "continuum"
team: "Occasions / Merchandising"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "Node.js 16.x"
  framework: "I-Tier (itier-server)"
  framework_version: "7.14.2"
  runtime: "Node.js"
  runtime_version: "16.x"
  build_tool: "webpack"
  package_manager: "npm"
---

# Occasions ITA Overview

## Purpose

occasions-itier (Occasions ITA) serves dynamic occasion-based deal browsing pages for Groupon customers. It applies merchandising themes, filters deals by relevant categories and facets, and aggregates data from upstream services (Campaign Service, Groupon V2 API, RAPI, Alligator) to deliver cohesive occasion landing pages. The service uses Memcached-backed caching and background polling to maintain responsive page rendering without placing direct load on upstream APIs on every request.

## Scope

### In scope
- Rendering occasion landing pages (`/occasions`, `/occasion/:occasion`, `/collection/:occasion`)
- Serving paginated deal JSON for AJAX-driven deal list updates
- Loading embedded card markup via the embedded-cards-loader endpoint
- Background polling and caching of Campaign Service data (divisions, themes, campaign configurations)
- Memcached-based caching of deal and campaign responses
- Manual cache control via `/cachecontrol` for operators
- Serving permalink-based occasion routes (`/:permalink_base`)

### Out of scope
- Deal catalog management and inventory (owned by `continuumDealCatalogService`)
- Recommendation ranking algorithms (owned by `continuumRelevanceApi` / RAPI)
- Faceting logic (owned by Alligator)
- User authentication and session management (delegated to `itier-user-auth`)
- Geo-resolution (delegated to GeoDetails API)
- Feature flag evaluation (delegated to Birdcage)

## Domain Context

- **Business domain**: Commerce / Merchandising / Deals Discovery
- **Platform**: Continuum
- **Upstream consumers**: Browser clients (Groupon web), internal CDN/proxy layers
- **Downstream dependencies**: Groupon V2 API, Campaign Service (ArrowHead), RAPI (recommendations), Alligator (faceting), GeoDetails API, Birdcage (feature flags), Memcached

## Stakeholders

| Role | Description |
|------|-------------|
| Merchandising / Occasions team | Service owners; manage themes and campaign configuration |
| Commerce platform engineers | Maintain I-Tier framework and infrastructure |
| Site reliability / ops | Monitor availability and cache health |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js) | 16.x | package.json `engines` |
| Framework | I-Tier (itier-server) | 7.14.2 | package.json dependency |
| Runtime | Node.js | 16.x | package.json `engines` |
| Build tool | webpack | 4.47.0 | package.json devDependency |
| Package manager | npm | | package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.14.2 | http-framework | Core I-Tier server: Express-based routing, middleware, SSR |
| itier-campaign-service-client | 1.2.1 | http-client | Polls Campaign Service (ArrowHead) for occasion configs |
| itier-cached | 8.1.3 | state-management | Memcached-backed caching helper for deal and campaign data |
| keldor | 7.3.7 | http-framework | Groupon internal templating / view rendering engine |
| itier-divisions | 7.2.6 | state-management | In-process division/locale data management |
| itier-groupon-v2-client | 4.2.5 | http-client | Fetches deal data from Groupon V2 API |
| itier-user-auth | 8.1.0 | auth | User authentication and session middleware |
| itier-tracing | 1.9.1 | metrics | Distributed tracing instrumentation |
| gofer | 4.0.0 | http-client | Base HTTP client used for upstream API calls |
| preact | 8.5.2 | ui-framework | Lightweight React-compatible component rendering (SSR + client) |
| grpn-card-ui | 6.169.7 | ui-framework | Groupon deal card UI components |
| webpack | 4.47.0 | build | Client-side asset bundling |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
