---
service: "itier-3pip"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "3rd-Party Inventory / Booking"
platform: "Continuum"
team: "3PIP Booking (3pip-booking@groupon.com)"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2017+"
  framework: "Express"
  framework_version: "4.14.0"
  runtime: "Node.js"
  runtime_version: "12.22.3"
  build_tool: "Webpack"
  build_tool_version: "4.44.1"
  package_manager: "npm"
---

# TPIS Booking ITA (itier-3pip) Overview

## Purpose

itier-3pip is the I-Tier booking and redemption iframe application for Groupon's 3rd-party partner (3PIP) commerce flows. It serves provider-specific booking UIs inside Groupon deal pages and orchestrates the end-to-end checkout and redemption process by coordinating calls to external provider APIs and internal Groupon services. The service renders server-side Preact/Redux UIs and acts as the authoritative integration layer between Groupon consumers and 3rd-party inventory providers such as Viator, Peek, AMC, Vivid, Grubhub, Mindbody, and HBW.

## Scope

### In scope

- Serving provider-specific booking and redemption iframe UIs (Viator, Peek, AMC, Vivid, Grubhub, Mindbody, HBW)
- Orchestrating the booking workflow: availability checks, checkout, order creation, and redemption
- Proxying and transforming requests between Groupon consumers and external provider APIs
- Session and response caching via Memcached
- Integrating with internal Groupon services (Deal Catalog, Orders, TPIS, ePODS, Groupon V2 Users/Deals/Accounts)
- Server-side rendering of the booking module UI using Preact and Redux

### Out of scope

- Deal creation and merchandising (handled by Deal Catalog)
- Order lifecycle management beyond initial creation (handled by Orders service)
- Raw provider inventory management (handled by TPIS — `continuumThirdPartyInventoryService`)
- Authentication and identity management (handled by Groupon V2 Users/Accounts)
- Global CDN or frontend asset delivery

## Domain Context

- **Business domain**: 3rd-Party Inventory / Booking
- **Platform**: Continuum
- **Upstream consumers**: Groupon consumers accessing deal pages via browser iframe
- **Downstream dependencies**: Viator API, Peek API, AMC API, Vivid API, Grubhub API, Mindbody API, HBW API, Deal Catalog (`continuumDealCatalogService`), Orders (`continuumOrdersService`), TPIS (`continuumThirdPartyInventoryService`), ePODS (`continuumEpodsService`), Groupon V2 (users, deals, accounts via `itier-groupon-v2-client`)

## Stakeholders

| Role | Description |
|------|-------------|
| 3PIP Booking Team | Service owner; builds, operates, and deploys itier-3pip (3pip-booking@groupon.com) |
| Groupon Consumers | End users who complete bookings through the iframe UI |
| Provider Partners | 3rd-party inventory providers whose booking APIs are proxied (Viator, Peek, AMC, Vivid, Grubhub, Mindbody, HBW) |
| Commerce Platform | Internal stakeholders depending on deal booking conversion metrics |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | ES2017+ | `package.json` |
| Runtime | Node.js | 12.22.3 | `Dockerfile` (alpine-node12) |
| Framework | Express | 4.14.0 | `package.json` |
| Server framework | itier-server | 6.2.0 | `package.json` |
| Build tool | Webpack | 4.44.1 | `package.json` |
| Package manager | npm | — | `package-lock.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `preact` | 8.5.2 | ui-framework | Server-side rendered UI components for booking iframes |
| `redux` | 3.7.2 | state-management | Client-side state management for booking UI flows |
| `itier-tpis-client` | 1.36.1 | http-framework | Client for TPIS (3rd-party inventory service) APIs |
| `itier-groupon-v2-client` | 4.2.2 | http-framework | Client for Groupon V2 users, deals, and accounts APIs |
| `@grpn/graphql` | 2.0.1 | http-framework | GraphQL client for internal Groupon graph APIs |
| `keldor` | 7.3.7 | http-framework | Internal Groupon HTTP client framework |
| `gofer` | 5.2.4 | http-framework | Outbound HTTP request client with service discovery |
| `groupon-steno` | 3.6.0 | logging | Structured logging library |
| `itier-instrumentation` | 9.11.2 | metrics | Metrics, tracing, and observability instrumentation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
