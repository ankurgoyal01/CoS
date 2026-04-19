---
service: "travel-browse"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Travel / Getaways"
platform: "Continuum"
team: "Getaways Engineering"
status: active
tech_stack:
  language: "JavaScript"
  language_version: ""
  framework: "itier-server / Express"
  framework_version: ""
  runtime: "Node.js"
  runtime_version: ""
  build_tool: "npm"
  package_manager: "npm"
---

# travel-browse Overview

## Purpose

travel-browse is an I-tier Node.js service that renders Getaways browse pages, SEO content, and hotel detail experiences for Groupon's travel vertical. The service receives HTTP requests from browsers and CDN edge nodes, fans out synchronous REST calls to a set of downstream APIs (RAPI, Getaways API, MARIS, LPAPI, Geodetails, and others), assembles page view models, and returns server-rendered HTML pages. It is the primary consumer-facing web tier for Getaways hotel search, browse, and inventory within the Continuum platform.

## Scope

### In scope

- Rendering Getaways browse and hotel search pages
- Rendering hotel detail and inventory pages with live market-rate pricing
- Rendering SEO landing pages for Getaways content
- Server-side rendering via the itier-server framework and React/Backbone
- Aggregating and caching API responses from RAPI, LPAPI, Getaways API, MARIS, Geodetails, and others
- Client-side experimentation and A/B testing via the Optimize Service
- Session and page-level caching via Memcached cluster
- SEO meta-tag generation and geo-aware page routing

### Out of scope

- Deal creation and merchant operations (Continuum commerce engine)
- Order processing and payment flows
- Getaways booking and checkout (separate service)
- User account management and subscription billing
- Map tile generation (delegated to `continuumMapProxyService`)
- Static asset hosting (delegated to `grouponCdn`)

## Domain Context

- **Business domain**: Travel / Getaways
- **Platform**: Continuum
- **Upstream consumers**: End-users via browser; CDN edge layer (`grouponCdn`); SEO crawlers
- **Downstream dependencies**: RAPI API, LPAPI Pages, Groupon V2 API, Geodetails V2 API, Getaways API (`continuumGetawaysApi`), Maris API, Subscriptions API, Remote Layout Service, Optimize Service, User Auth Service, Map Proxy Service (`continuumMapProxyService`), Memcache Cluster, Groupon CDN

## Stakeholders

| Role | Description |
|------|-------------|
| Getaways Engineering | Owns, develops, and operates the service |
| Getaways Product | Defines browse and search experience requirements |
| SEO / Growth | Relies on SSR output for indexable Getaways pages |
| Platform / Infra | Manages deployment infrastructure and Memcache provisioning |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js) | — | Architecture inventory |
| Framework | itier-server / Express | — | Architecture inventory |
| Runtime | Node.js | — | Architecture inventory |
| Build tool | npm | — | Architecture inventory |
| Package manager | npm | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | — | http-framework | Groupon I-tier SSR application framework |
| Express | — | http-framework | HTTP server and routing layer |
| React | — | ui-framework | Server-side and client-side component rendering |
| Backbone | — | ui-framework | Client-side view and model layer |
| itier-render | — | ui-framework | Server-side rendering integration for itier-server |
| itier-cached | — | state-management | Response caching via Memcached |
| itier-routing | — | http-framework | Route definition and dispatch for itier-server |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
