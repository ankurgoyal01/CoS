---
service: "html-site-map"
title: Overview
generated: "2026-03-03"
type: overview
domain: "SEO / Discovery"
platform: "Continuum"
team: "SEO"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2021"
  framework: "itier-server"
  framework_version: "7.7.2"
  runtime: "Node.js"
  runtime_version: "^16"
  build_tool: "Webpack 5"
  package_manager: "npm"
---

# HTML Sitemap Overview

## Purpose

html-site-map is a server-side rendered Node.js web application that generates hierarchical HTML sitemaps for all Groupon regional storefronts (`.com`, `.co.uk`, `.fr`, and other TLDs). It serves three levels of sitemap pages — states/regions, cities, and deal categories — to improve search engine crawlability, support users navigating the site structure, and provide accessibility-friendly overviews of Groupon's content geography. The service retrieves all location and category crosslink data from the LPAPI service at request time and renders fully composed HTML responses.

## Scope

### In scope

- Rendering the top-level sitemap home page listing all states/regions (`/sitemap`)
- Rendering per-region city listing pages (`/sitemap/{regionSlug}`)
- Rendering per-city deal category listing pages (`/sitemap/{regionSlug}/{citySlug}`)
- Fetching location and category crosslinks from LPAPI and formatting them as navigable HTML links
- Server-side rendering of sitemap pages using Preact with locale-aware page metadata (title, description)
- Composing shared page layout (header, navigation, breadcrumbs) from the remote layout service
- Rendering a custom 404 error page for unknown sitemap paths
- Delivering static assets (CSS, JS) from the Groupon CDN

### Out of scope

- XML sitemaps (handled by a separate service)
- Deal/offer content pages (handled by other Continuum services)
- Location data management or geographic data storage (owned by LPAPI)
- User authentication or personalization
- Search functionality

## Domain Context

- **Business domain**: SEO / Discovery
- **Platform**: Continuum
- **Upstream consumers**: Web crawlers (e.g. Googlebot), end users navigating via `https://www.groupon.{tld}/sitemap`, the Groupon Routing Service which routes `/sitemap` path-prefix requests to this service
- **Downstream dependencies**: LPAPI (`continuumApiLazloService`) for all location and category crosslink data; Remote Layout service for shared page shell (header, footer, navigation)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | SEO team (seo-dev@groupon.com) |
| On-Call | seo-alerts@groupon.pagerduty.com — PagerDuty service PLAI6WB |
| Team Wiki | https://groupondev.atlassian.net/wiki/spaces/GSEO/overview |
| Mailing List | computational-seo@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | ES2021 (Node ^16) | `package.json` engines field |
| Framework | itier-server | 7.7.2 | `package.json` dependencies |
| Runtime | Node.js | ^16 | `.nvmrc`, `package.json` engines |
| Build tool | Webpack | 5.40.0 | `package.json` devDependencies |
| Package manager | npm | (npm ci) | `package-lock.json`, Dockerfile |
| UI rendering | Preact | 10.5.13 | `package.json` dependencies |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `itier-server` | 7.7.2 | http-framework | Core HTTP server and middleware framework for Groupon ITA apps |
| `@grpn/lpapi-client` | 1.9.8 | http-client | Client adapter for fetching location/crosslink data from LPAPI |
| `preact` | 10.5.13 | ui-framework | Lightweight React-compatible component rendering (SSR) |
| `@grpn/preact-page` | 2.4.2 | ui-framework | Groupon Preact page composition and SSR wrapper |
| `itier-routing` | 5.1.7 | http-framework | URL-to-handler route registration |
| `itier-localization` | 10.4.0 | serialization | i18n/l10n support for locale-aware page metadata |
| `keldor` | 7.3.7 | http-framework | Configuration and service-client orchestration layer |
| `keldor-config` | 4.23.2 | http-framework | Environment-layered CSON config loader |
| `itier-instrumentation` | 9.10.4 | metrics | Request tracing and performance instrumentation |
| `itier-tracing` | 1.6.1 | metrics | Distributed tracing support |
| `remote-layout` | 10.10.0 | ui-framework | Fetches shared page shell (header, nav, footer) from layout service |
| `itier-feature-flags` | 2.2.2 | validation | Runtime feature flag evaluation |
| `@grpn/graphql` | 4.0.0 | http-client | GraphQL client (available in framework, not currently used by sitemap routes) |
| `itier-cached` | 8.1.3 | http-framework | Response caching support |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
