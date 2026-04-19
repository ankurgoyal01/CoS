---
service: "itier-ttd-booking"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "TTD / GLive Checkout"
platform: "Continuum"
team: "TTD.CX (rprasad, ttd-dev.cx@groupon.com)"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "Node.js 16"
  framework: "Express"
  framework_version: "4.16.4"
  runtime: "Node.js"
  runtime_version: "16"
  build_tool: "Webpack"
  build_tool_version: "4.43.0"
  package_manager: "npm"
---

# ITier TTD Booking (GLive Checkout) Overview

## Purpose

`itier-ttd-booking` is a Node.js ITier application that serves the GLive checkout experience for Groupon's Things-To-Do (TTD) vertical. It renders the booking widget, manages the reservation spinner and status polling flow, and delivers TTD pass content (cards) for deals that include digital pass assets. The service acts as a server-side rendering and orchestration layer between the browser and downstream Continuum platform services.

## Scope

### In scope

- Rendering the GLive booking widget page (`/live/checkout/booking/{dealId}`)
- Serving the reservation spinner/loading page (`/live/deals/{dealId}/reservation`)
- Polling and reporting reservation status (`/live/deals/{dealId}/reservation/status.json`)
- Rendering the booking error page (`/live/checkout/error`)
- Serving TTD pass deal content (`/ttd-pass-deals`)
- Orchestrating availability and deal data assembly from GAPI V2 and GLive Inventory Service
- Applying Expy/Optimizely experimentation to booking widget variants

### Out of scope

- Payment processing and order creation (handled by Continuum order services)
- Deal catalog management and pricing (handled by `continuumDealCatalogService`)
- User account management and authentication (handled by `continuumUsersService`)
- Inventory ownership and reservation lifecycle management (owned by GLive Inventory Service)
- TTD pass issuance and storage (owned by Alligator Cards Service)

## Domain Context

- **Business domain**: TTD / GLive Checkout
- **Platform**: Continuum
- **Upstream consumers**: Browser clients loading GLive checkout flows; MBNXT frontend via server-side page composition
- **Downstream dependencies**: GAPI V2 (via `continuumDealCatalogService` and `continuumUsersService` through `apiProxy`), GLive Inventory Service (`continuumGLiveInventoryService`), Alligator Cards Service, Layout Service, Expy/Optimizely

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | TTD.CX team — rprasad, ttd-dev.cx@groupon.com |
| Platform Team | Continuum platform — provides itier-server, API proxy, and shared middleware |
| Consumers | GLive checkout users; downstream voucher/order systems that depend on reservation state |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js) | 16 | Summary / package.json |
| Framework | Express | 4.16.4 | Summary / package.json |
| ITier server | itier-server | 7.8.0 | Summary / package.json |
| Build tool | Webpack | 4.43.0 | Summary / package.json |
| Package manager | npm | — | — |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.8.0 | http-framework | Groupon ITier application scaffold — wraps Express with platform conventions |
| Express | 4.16.4 | http-framework | HTTP routing and middleware |
| Preact | 8.3.1 | ui-framework | Lightweight React-compatible UI rendering for booking widget components |
| Backbone | 1.4.0 | state-management | Client-side model/view layer for reservation spinner state |
| Webpack | 4.43.0 | build | Asset bundling for client-side JS and CSS |
| itier-client-platform | — | http-framework | Platform HTTP client with Memcached session caching |
| Expy / Optimizely | — | validation | A/B experimentation and feature flag evaluation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
