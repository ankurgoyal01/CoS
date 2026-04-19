---
service: "itier-tpp"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Merchant Operations / 3PIP"
platform: "Continuum"
team: "3pip-booking@groupon.com"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2020"
  framework: "Express"
  framework_version: "4.17.x"
  runtime: "Node.js"
  runtime_version: "^16"
  build_tool: "Webpack"
  build_tool_version: "4"
  package_manager: "npm >=5.0.0"
---

# I-Tier Third Party Partner Portal Overview

## Purpose

I-Tier TPP (Third Party Partner Portal) is the internal web application through which Groupon's 3PIP operations team and merchant partners manage the full lifecycle of third-party booking integrations. It provides server-rendered and client-interactive pages built on the I-Tier application framework (Express + Preact) to configure partners, onboard merchants, map Groupon deals to booking-platform products, and monitor operational metrics. The portal acts as the primary operational interface between Groupon's partner data layer (Partner Service / PAPI) and external booking platforms such as Booker and Mindbody.

## Scope

### In scope

- Partner configuration management: create, read, update, and review partner configurations via `/api/partner_configurations` and `/admin/partner-config` routes
- Onboarding configuration: create and manage merchant onboarding workflows via `/onboarding_configuration` routes
- Booking integration management: Booker-specific merchant mapping and deal lifecycle via `/partnerbooking` routes
- TTD (The Ticket Doctor) integration management: deal and merchant mapping via `/ttd` routes
- Merchant management views: browsing and editing HBW merchant deals via `/merchants` routes
- Partner redirect shortcuts via `/goto/{partnerName}` routes
- Operational metrics dashboards via `/metrics/merchants` and `/metrics/uptime` routes
- Serving the portal UI as server-rendered HTML with Preact-powered client-side components

### Out of scope

- Storing partner or merchant data directly (delegated to Partner Service / PAPI)
- Deal catalog ownership (delegated to Deal Catalog Service)
- Consumer-facing deal discovery or purchasing
- Groupon V2 API entity management (read-only consumption via API Lazlo)
- Geographic taxonomy management (read-only from Geo Details Service)

## Domain Context

- **Business domain**: Merchant Operations / Third-Party Partner Integration (3PIP)
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon operations staff (partner ops, onboarding teams) and authorized merchant users authenticating through Doorman
- **Downstream dependencies**: Partner Service (PAPI), API Lazlo / Groupon V2 API, Deal Catalog Service, Booker API, Mindbody API, Geo Details Service

## Stakeholders

| Role | Description |
|------|-------------|
| 3PIP Operations | Primary day-to-day users; manage partner configurations and onboarding workflows |
| Partner Onboarding Team | Use the portal to register and configure new merchant partners |
| Merchant Partners | External users with scoped access to manage their own deal and booking configurations |
| Engineering (3pip-booking) | Owns and maintains the service; responds to incidents via PagerDuty |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js) | ES2020 | `package.json` engines |
| Framework | Express | 4.17.x | `package.json` dependencies |
| UI Framework | Preact | 8.5.x | `package.json` dependencies |
| Runtime | Node.js | ^16 | `package.json` engines |
| Build tool | Webpack | 4.x | `package.json` devDependencies |
| Package manager | npm | >=5.0.0 | `package.json` engines |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `express` | ^4.17.1 | http-framework | HTTP server and routing |
| `preact` | ^8.5.2 | ui-framework | Server-rendered and client-side component UI |
| `redux` | ^4.0.4 | state-management | Client-side application state management |
| `@reduxjs/toolkit` | ^1.5.0 | state-management | Simplified Redux store configuration |
| `gofer` | ^2.1.0 | http-client | HTTP client for downstream service calls (Partner Service, Groupon V2, Deal Catalog) |
| `@grpn/booker-client` | ^1.3.2 | http-client | Booker API integration client |
| `@grpn/mindbody-client` | ^2.0.0 | http-client | Mindbody API integration client |
| `itier-server` | ^5.36.5 | http-framework | I-Tier opinionated server bootstrap (cluster, middleware, routing) |
| `itier-user-auth` | ^8.1.0 | auth | Macaroon-based authentication via Doorman |
| `itier-instrumentation` | ^9.10.4 | metrics | Wavefront / Steno metrics and logging |
| `itier-feature-flags` | ^1.0.1 | feature-flags | gconfig-backed feature flag evaluation |
| `keldor` | ^7.3.7 | config | Environment-aware configuration loader (CSON) |
| `itier-tracing` | ^1.6.1 | metrics | Distributed tracing instrumentation |
| `csurf` | ^1.6.4 | auth | CSRF protection middleware |
| `mocha` | ^9.0.1 | testing | Unit and integration test runner |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for a full list.
