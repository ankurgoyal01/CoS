---
service: "html-site-map"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumHtmlSiteMapWeb"]
---

# Architecture Context

## System Context

html-site-map is a container within the **Continuum Platform** (`continuumSystem`) — Groupon's core commerce engine. It sits at the public-facing edge of the Continuum platform, receiving inbound HTTP requests from web crawlers and human users navigating `https://www.groupon.{tld}/sitemap`. The Groupon Routing Service directs all `/sitemap` path-prefix traffic to this service via Hybrid Boundary ingress. At runtime, the service reaches out to `continuumApiLazloService` (LPAPI) to fetch the geographic and category crosslink data required to build each page, and to a shared Remote Layout container to compose the standard Groupon page shell.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| HTML Site Map Web | `continuumHtmlSiteMapWeb` | WebApp | Node.js / itier-server | 7.7.2 | Node.js web application that renders region/city/category HTML sitemap pages. |

## Components by Container

### HTML Site Map Web (`continuumHtmlSiteMapWeb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Request Routing | Maps incoming sitemap URLs to route handlers | Express/OpenAPI routes (`itier-routing`) |
| Home Sitemap Handler | Builds the top-level state/region sitemap page for `/sitemap` | Node.js module (`modules/home`) |
| Cities Sitemap Handler | Builds state-to-city sitemap pages for `/sitemap/{regionSlug}` | Node.js module (`modules/cities`) |
| Categories Sitemap Handler | Builds city-to-category sitemap pages for `/sitemap/{regionSlug}/{citySlug}` | Node.js module (`modules/categories`) |
| LPAPI Client Adapter | Wraps LPAPI calls and normalizes crosslink data into sitemap-ready link arrays | `@grpn/lpapi-client` adapter (`modules/support/lpapi-helper.js`) |
| Server-side Renderer | Composes Preact component trees and page metadata into full HTML responses | Preact SSR / `@grpn/preact-page` |
| Navigation Views | Shared breadcrumb and navigation components used across all sitemap pages | Preact components (`modules/shared/views`) |
| Error Handler | Renders the custom 404 experience for unknown sitemap paths | Node.js module (`modules/error`) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumHtmlSiteMapWeb` | `continuumApiLazloService` | Reads location and category crosslink data to populate sitemap pages | HTTPS/JSON |
| Web crawler / user agent | `continuumHtmlSiteMapWeb` | Requests sitemap pages (stub-only in DSL — tracked in routing config) | HTTPS |
| `continuumHtmlSiteMapWeb` | Remote Layout container | Retrieves shared page layout fragments (header, nav, footer) | HTTPS (stub-only in DSL) |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-html-site-map-web`
