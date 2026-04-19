---
service: "pull"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumPullItierApp", "continuumPullConsumerClients"]
---

# Architecture Context

## System Context

Pull sits within the `continuumSystem` (Continuum Platform — Groupon's core commerce engine). It is the consumer-facing SSR layer for deal discovery, positioned between end-user browsers/mobile clients and a set of internal Continuum microservices. Consumer clients (`continuumPullConsumerClients`) issue HTTPS requests to Pull, which orchestrates calls to multiple internal services and returns fully-rendered HTML pages with client-side hydration payloads.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Pull I-Tier App | `continuumPullItierApp` | Service | Node.js, itier-server, Preact/TypeScript | 16 / 7.14.2 / 10.5.13 | SSR application serving homepage, browse, search, local, goods, and gifting pages |
| Consumer Web Clients | `continuumPullConsumerClients` | Client | Browser/Mobile Client | — | Web and mobile clients requesting browse/search/home pages |

## Components by Container

### Pull I-Tier App (`continuumPullItierApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Route Dispatcher (`pullRouteDispatcher`) | Bootstraps route matching and dispatches matched requests to registered feature module controllers | Node.js Router |
| Page Controllers (`pullPageControllers`) | Module controller layer handling request lifecycle and action orchestration; delegates to domain orchestrators and emits telemetry | Controller Layer |
| Search/Browse Orchestrator (`pullSearchBrowseOrchestrator`) | Coordinates search, browse, local, goods, and giftshop request workflows; calls feature flags, geo resolver, API client facade, and render composer | Domain Orchestrator |
| Homepage Orchestrator (`pullHomepageOrchestrator`) | Builds homepage-specific card and layout responses across desktop and touch variants; calls feature flags, API client facade, and render composer | Domain Orchestrator |
| API Client Facade (`pullApiClientFacade`) | Encapsulates outbound client calls to Relevance API, API Proxy, LPAPI, UGC, Wishlist, and related services | Service Client Layer |
| Feature Flag Client (`pullFeatureFlagClient`) | Resolves feature flags and experiments for request decisions and rendering branches via Birdcage | Experiment Client |
| Geo Resolver (`pullGeoResolver`) | Determines division and location context using GeoPlaces and request metadata | Geo Context Service |
| Render Composer (`pullRenderComposer`) | Composes server-side Preact views, Mustache templates, and frontend entrypoint hydration data for HTML response | Rendering Pipeline |
| Telemetry Publisher (`pullTelemetryPublisher`) | Publishes request metrics, distributed tracing, and application telemetry via itier-instrumentation | Observability |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumPullConsumerClients` | `continuumPullItierApp` | Requests homepage, browse, search, local, goods, and gifting pages | HTTPS |
| `continuumPullItierApp` | `apiProxy` | Calls internal gateway endpoints for aggregated APIs | REST/HTTPS |
| `continuumPullItierApp` | `continuumBirdcageService` | Fetches feature-flag and experiment configuration | REST/HTTPS |
| `continuumPullItierApp` | `continuumGeoPlacesService` | Resolves geographic and place metadata | REST/HTTPS |
| `continuumPullItierApp` | `continuumLayoutService` | Fetches page layout and widget configuration | REST/HTTPS |
| `continuumPullItierApp` | `continuumRelevanceApi` | Requests search and browse relevance data | REST/HTTPS |
| `continuumPullItierApp` | `continuumLpapiService` | Fetches landing page metadata and route context | REST/HTTPS |
| `continuumPullItierApp` | `continuumUgcService` | Fetches user-generated ratings and reviews | REST/HTTPS |
| `continuumPullItierApp` | `continuumWishlistService` | Reads and updates wishlist data for signed-in users | REST/HTTPS |
| `pullRouteDispatcher` | `pullPageControllers` | Dispatches matched requests to controller handlers | direct |
| `pullPageControllers` | `pullSearchBrowseOrchestrator` | Delegates browse/search/local/goods workflows | direct |
| `pullPageControllers` | `pullHomepageOrchestrator` | Delegates homepage workflows | direct |
| `pullSearchBrowseOrchestrator` | `pullFeatureFlagClient` | Reads experiment treatments and feature toggles | direct |
| `pullSearchBrowseOrchestrator` | `pullGeoResolver` | Resolves location and division context | direct |
| `pullSearchBrowseOrchestrator` | `pullApiClientFacade` | Requests deals, facets, cards, and supporting API data | direct |
| `pullSearchBrowseOrchestrator` | `pullRenderComposer` | Builds rendered page and hydration payload | direct |
| `pullHomepageOrchestrator` | `pullFeatureFlagClient` | Reads homepage experiment treatments | direct |
| `pullHomepageOrchestrator` | `pullApiClientFacade` | Requests homepage cards and content | direct |
| `pullHomepageOrchestrator` | `pullRenderComposer` | Builds rendered homepage response | direct |
| `pullPageControllers` | `pullTelemetryPublisher` | Emits request and error telemetry | direct |

## Architecture Diagram References

- Container runtime context: `containers-pull-runtime-context`
- Component architecture: `components-pull-component-architecture`
- Browse request dynamic flow: `dynamic-pull-browse-request-flow`
