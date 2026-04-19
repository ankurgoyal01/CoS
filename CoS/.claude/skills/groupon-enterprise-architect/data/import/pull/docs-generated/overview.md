---
service: "pull"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Consumer Discovery"
platform: "Continuum"
team: "Ion (ion@groupon.com)"
status: active
tech_stack:
  language: "TypeScript/JavaScript"
  language_version: "ES2020+"
  framework: "itier-server"
  framework_version: "7.14.2"
  runtime: "Node.js"
  runtime_version: "16"
  build_tool: "Webpack"
  build_tool_version: "5.73.0"
  package_manager: "npm"
---

# Pull Overview

## Purpose

Pull is the server-side rendering (SSR) application responsible for delivering Groupon's consumer-facing discovery pages: Homepage, Browse, Search, Local listings, Goods, and Gifting. It runs as a Node.js I-Tier application using the `itier-server` framework, composing data from multiple upstream APIs into fully-rendered Preact HTML responses. Pull is the primary entry point for unauthenticated and authenticated Groupon web traffic for deal discovery.

## Scope

### In scope

- Server-side rendering of the Groupon Homepage (`GET /`)
- Server-side rendering of Browse pages (`GET /browse`)
- Server-side rendering of Search results pages (`GET /search`)
- Server-side rendering of Local listing pages (`GET /local`)
- Server-side rendering of Goods pages (`GET /goods`)
- Server-side rendering of Gifting pages (`GET /gifting`)
- Feature flag and experiment resolution per request via Birdcage
- Geographic and division context resolution per request
- Outbound API orchestration to Relevance API, LPAPI, API Proxy, Layout Service, UGC, and Wishlist
- Request and performance telemetry emission
- Wishlist data read and update for signed-in users

### Out of scope

- Deal detail pages (handled by separate I-Tier services)
- Checkout and payment flows (handled by separate Continuum services)
- Authentication and session management (delegated to upstream infrastructure)
- Content authoring or deal ingestion
- Mobile native app responses

## Domain Context

- **Business domain**: Consumer Discovery — surfaces deals, categories, and search results to Groupon shoppers
- **Platform**: Continuum
- **Upstream consumers**: Browser and mobile web clients (`continuumPullConsumerClients`) via HTTPS
- **Downstream dependencies**: API Proxy (`apiProxy`), Birdcage (`continuumBirdcageService`), GeoPlaces (`continuumGeoPlacesService`), Layout Service (`continuumLayoutService`), Relevance API (`continuumRelevanceApi`), LPAPI (`continuumLpapiService`), UGC (`continuumUgcService`), Wishlist (`continuumWishlistService`)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Ion | Owning team — feature development, on-call, and incident response (ion@groupon.com) |
| Groupon Consumers | End users browsing, searching, and discovering deals on groupon.com |
| Platform/Infrastructure | Responsible for I-Tier hosting, routing, and deployment pipeline |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript/JavaScript | ES2020+ | Summary inventory |
| Framework | itier-server | 7.14.2 | Summary inventory |
| UI Framework | Preact | 10.5.13 | Summary inventory |
| Runtime | Node.js | 16 | Summary inventory |
| Build tool | Webpack | 5.73.0 | Summary inventory |
| Package manager | npm | | Summary inventory |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.14.2 | http-framework | Core I-Tier server runtime — request lifecycle, routing, controller wiring |
| Preact | 10.5.13 | ui-framework | Server-side and client-side UI rendering (React-compatible, lightweight) |
| Webpack | 5.73.0 | build-tool | Module bundling for server and client assets |
| itier-feature-flags | 3.2.0 | feature-flags | Feature flag and experiment evaluation via Birdcage integration |
| itier-routing | 5.1.8 | http-framework | Route registration and dispatch within the I-Tier runtime |
| keldor | 7.3.9 | http-client | Internal HTTP client library for outbound API calls |
| grpn-wh-templates | 6.72.3 | ui-framework | Groupon shared web template and layout components |
| itier-groupon-v2-client | 4.2.5 | http-client | Client library for Groupon V2 API interactions |
| axios | 1.5.1 | http-client | HTTP client for outbound REST calls to upstream services |
| @tanstack/react-query | 4.29.12 | state-management | Server and client-side data fetching and caching |
| itier-instrumentation | 9.13.4 | metrics | Request tracing, metrics, and telemetry instrumentation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
