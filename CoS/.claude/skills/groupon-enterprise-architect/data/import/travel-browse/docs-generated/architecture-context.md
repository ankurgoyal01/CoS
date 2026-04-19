---
service: "travel-browse"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumGetawaysBrowseWebApp]
---

# Architecture Context

## System Context

travel-browse is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It serves as the consumer-facing SSR web tier for the Getaways travel vertical, receiving browser requests routed through the CDN edge layer and calling a fan-out of internal and external APIs to compose and render Getaways browse and hotel detail pages. Most downstream dependencies are defined as stubs in the local architecture model and resolved as external Continuum services in the broader central architecture model.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Getaways Browse Web App | `continuumGetawaysBrowseWebApp` | WebApp | Node.js, itier-server, Express | — | Serves Getaways browse pages, SEO content, and hotel detail experiences |

## Components by Container

### Getaways Browse Web App (`continuumGetawaysBrowseWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `requestRouting` — Routing and Controllers | Defines HTTP routes and dispatches requests to page controllers | itier-routing, Express |
| `pageModules` — Page Modules | Builds page data, presenters, and view models for each page type | Node.js modules |
| `apiClients` — API Client Integrations | Wraps calls to downstream APIs (RAPI, LPAPI, Getaways API, MARIS, etc.) | itier-server HTTP client |
| `renderingEngine` — Rendering Engine | Server-side renders React/Backbone views and templates into HTML | React, itier-render |
| `travelBrowse_cacheAccess` — Cache Access | Reads and writes cached configuration and API responses | itier-cached, Memcached |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `requestRouting` | `pageModules` | Dispatches incoming HTTP requests to page controllers | Direct |
| `pageModules` | `apiClients` | Fetches data for page composition | Direct |
| `pageModules` | `renderingEngine` | Builds view models and triggers SSR | Direct |
| `pageModules` | `travelBrowse_cacheAccess` | Reads and writes page-level cached data | Direct |
| `apiClients` | `travelBrowse_cacheAccess` | Uses cached API responses when available | Direct |
| `continuumGetawaysBrowseWebApp` | `continuumGetawaysApi` | Fetches Getaways inventory | HTTP |
| `continuumGetawaysBrowseWebApp` | `continuumMapProxyService` | Loads map tiles and map JS API | HTTP |
| `continuumGetawaysBrowseWebApp` | `rapiApi` | Searches and retrieves deals | HTTP |
| `continuumGetawaysBrowseWebApp` | `lpapiPages` | Fetches landing page content | HTTP |
| `continuumGetawaysBrowseWebApp` | `grouponV2Api` | Reads Groupon V2 data | HTTP |
| `continuumGetawaysBrowseWebApp` | `geodetailsV2Api` | Resolves geo details | HTTP |
| `continuumGetawaysBrowseWebApp` | `marisApi` | Fetches hotel availability and market-rate pricing | HTTP |
| `continuumGetawaysBrowseWebApp` | `subscriptionsApi` | Reads subscription data | HTTP |
| `continuumGetawaysBrowseWebApp` | `remoteLayoutService` | Loads shared header/footer layout | HTTP |
| `continuumGetawaysBrowseWebApp` | `optimizeService` | Evaluates experiments and feature flags | HTTP |
| `continuumGetawaysBrowseWebApp` | `userAuthService` | Loads user session context | HTTP |
| `continuumGetawaysBrowseWebApp` | `memcacheCluster` | Reads and writes cached data | Memcached |
| `continuumGetawaysBrowseWebApp` | `grouponCdn` | Loads static assets and images | HTTP |

## Architecture Diagram References

- Container: `containers-travel-browse`
- Component: `components-travel-browse`

> No dynamic views are currently defined in the architecture DSL. See [Flows](flows/index.md) for process-level sequence diagrams.
