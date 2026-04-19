---
service: "merchant-page"
title: Overview
generated: "2026-03-03"
type: overview
domain: "SEO / Merchant Discovery"
platform: "Continuum"
team: "SEO"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2020+"
  framework: "itier-server"
  framework_version: "7.14.2"
  runtime: "Node.js"
  runtime_version: "^16"
  build_tool: "Webpack"
  package_manager: "npm ^8"
---

# Merchant Place Pages Overview

## Purpose

The merchant-page service (Merchant Place Pages ITA) provides a server-rendered place page at `/biz/:citySlug/:merchantSlug` for every merchant in Groupon's catalogue, regardless of whether that merchant has an active Groupon deal. Each page aggregates merchant profile data, user-generated reviews, related deals from the Relevance API, and a signed static map — then renders a complete HTML page using Preact server-side rendering with client-side hydration. It also exposes lightweight AJAX fragment endpoints for lazy-loaded deal cards, paginated reviews, and map image URL signing.

## Scope

### In scope

- Serving the primary merchant place page (`GET /biz/{citySlug}/{merchantSlug}`)
- Fetching and aggregating merchant/place data from `mpp-service` via `continuumUniversalMerchantApi`
- Fetching related deal cards from the Relevance API (`continuumRelevanceApi`) and rendering them with `grpn-card-ui`
- Fetching paginated merchant reviews from `continuumUgcService`
- Generating signed static map image URLs via `gims`
- Proxying single-deal redirects to `continuumApiLazloService` when the `proxy_deal` feature flag is enabled
- Server-side rendering of the full page layout with Preact and client-side hydration
- Generating JSON-LD structured data (schema.org) in the page `<head>`
- Serving fragment HTML for RAPI deal cards (`GET /merchant-page/rapi/{city}/{permalink}`)
- Serving paginated UGC review data (`GET /merchant-page/reviews`)
- Serving signed map redirect URLs (`GET /merchant-page/maps/image`)

### Out of scope

- Merchant profile data storage and management (owned by `mpp-service`)
- Deal creation, pricing, and inventory (owned by the broader Continuum platform)
- User-generated content storage (owned by `ugc-places`)
- Routing and load balancing (handled by the Routing Service and Hybrid Boundary)
- Map tile serving (delegated to `gims` / MapTiler)

## Domain Context

- **Business domain**: SEO / Merchant Discovery
- **Platform**: Continuum
- **Upstream consumers**: Public web users via the Routing Service and Hybrid Boundary; internal AJAX calls from the hydrated browser client
- **Downstream dependencies**: `continuumUniversalMerchantApi` (merchant/place data), `continuumRelevanceApi` (deal cards), `continuumUgcService` (reviews), `gims` (map signing), `continuumApiLazloService` (deal proxy redirects), `layout-service` (page chrome)

## Stakeholders

| Role | Description |
|------|-------------|
| SEO Team (seo-dev@groupon.com) | Owns the service; responsible for development, deployment, and on-call |
| SRE | Monitors service health; receives alerts via seo_alerts@groupon.com and PagerDuty |
| Merchant Discovery consumers | Search engines and users who rely on `/biz/` URLs for merchant discovery |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | ES2020+ | `package.json` |
| Runtime | Node.js | ^16 | `package.json` engines / `.nvmrc` |
| HTTP Framework | itier-server | 7.14.2 | `package.json` dependencies |
| UI Renderer | Preact + itier-render | ^10.5.13 / ^2.0.3 | `package.json` |
| Build tool | Webpack | ^5.40.0 | `package.json` devDependencies |
| Package manager | npm | ^8 | `package.json` engines |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `itier-server` | ^7.14.2 | http-framework | Core I-Tier application server (routing, request lifecycle, SSR orchestration) |
| `preact` | ^10.5.13 | ui-framework | Lightweight React-compatible renderer for SSR and client hydration |
| `@grpn/graphql` | ^4.0.0 | http-client | GraphQL client used for GAPI/GraphQL-based upstream calls |
| `gofer` | ^5.2.4 | http-client | Service-to-service HTTP client with timeout and retry support |
| `itier-rapi-client` | ^3.5.5 | http-client | Typed client for Relevance API (deal cards search) |
| `itier-mpp-service-client` | ^1.2.2 | http-client | Typed client for MPP merchant/place data APIs |
| `itier-ugc-client` | ^6.4.1 | http-client | Typed client for UGC reviews APIs |
| `grpn-card-ui` | ^6.169.2 | ui-framework | Renders deal card HTML fragments from Relevance API responses |
| `keldor` | ^7.3.7 | configuration | Runtime configuration loader (reads CSON config files and env overrides) |
| `itier-feature-flags` | ^2.2.2 | configuration | Feature flag evaluation at request time |
| `itier-cached` | ^8.1.3 | caching | In-process response caching with configurable TTL |
| `itier-instrumentation` | ^9.10.4 | metrics | Wavefront / InfluxDB metrics emission |
| `itier-localization` | ^10.3.0 | i18n | Locale, language, and brand resolution per request |
| `@grpn/itier-maps` | ^1.1.3 | mapping | Generates signed static map image URLs via MapTiler/GIMS proxy |
| `remote-layout` | ^10.12.0 | ui-framework | Fetches and injects remote page chrome (header/footer) from `layout-service` |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for a full list.
