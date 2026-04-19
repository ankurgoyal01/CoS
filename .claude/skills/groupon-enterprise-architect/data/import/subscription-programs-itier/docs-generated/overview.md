---
service: "subscription-programs-itier"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Loyalty / Subscriptions / Membership"
platform: "continuum"
team: "Select / Subscriptions"
status: active
tech_stack:
  language: "JavaScript/CoffeeScript"
  language_version: "Node.js 10.16.3"
  framework: "I-Tier (itier-server)"
  framework_version: "7.9.1"
  runtime: "Node.js"
  runtime_version: "10.16.3"
  build_tool: "webpack"
  package_manager: "npm"
---

# Select I-Tier Overview

## Purpose

subscription-programs-itier (Select I-Tier) is the Continuum-platform web application responsible for the Groupon Select subscription membership experience. It renders enrollment landing pages with variant-based offer presentation, handles the subscription purchase flow including payment collection, tracks membership status via polling, and displays member benefits. The service acts as the primary front-end for the Groupon Select loyalty program, coordinating with the Groupon Subscriptions API and Groupon V2 Select Membership client for all membership lifecycle operations.

## Scope

### In scope
- Rendering the Groupon Select landing page (`/programs/select`) and purchase variant pages (`/programs/select/purchg1`, `/programs/select/purchgg`, `/programs/select/purchge`)
- Rendering the Select benefits page (`/programs/select/benefits`)
- Handling subscription enrollment via `POST /programs/select/subscribe`
- Presenting the add-payment-card step (`/programs/select/subscribe/addcard`)
- Rendering the post-enrollment confirmation page (`/programs/select/confirmation`)
- Polling subscription status after enrollment initiation (`GET /programs/select/poll`)
- Embedded webview support for mobile app integration
- Tracking enrollment events via Tracking Hub

### Out of scope
- Subscription billing logic and payment processing (owned by Groupon Subscriptions API)
- Benefit catalog management (owned by Groupon Subscriptions API)
- User authentication and session management (delegated to `itier-user-auth`)
- Feature flag evaluation (delegated to Birdcage)
- Geo-resolution (delegated to GeoDetails API)

## Domain Context

- **Business domain**: Loyalty / Subscriptions / Membership
- **Platform**: Continuum
- **Upstream consumers**: Browser clients (Groupon web), Groupon mobile app (via embedded webview)
- **Downstream dependencies**: Groupon Subscriptions API, Groupon V2 API (Select Membership), Birdcage (feature flags), GeoDetails API, Tracking Hub

## Stakeholders

| Role | Description |
|------|-------------|
| Select / Subscriptions team | Service owners; manage membership product features and enrollment flows |
| Commerce platform engineers | Maintain I-Tier framework and infrastructure |
| Mobile teams | Consume the embedded webview flow for in-app Select enrollment |
| Site reliability / ops | Monitor availability and enrollment funnel health |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript / CoffeeScript | Node.js 10.16.3 | package.json `engines` |
| Framework | I-Tier (itier-server) | 7.9.1 | package.json dependency |
| Runtime | Node.js | 10.16.3 | package.json `engines` |
| Build tool | webpack | 4.34.0 | package.json devDependency |
| Package manager | npm | | package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.9.1 | http-framework | Core I-Tier server: Express-based routing, middleware, SSR |
| itier-subscriptions-client | 3.1.0 | http-client | Calls Groupon Subscriptions API for membership lifecycle operations |
| itier-groupon-v2-select-membership | 1.2.0 | http-client | Fetches Groupon Select membership state from V2 API |
| bluebird | 3.3.4 | scheduling | Promise library used for async control flow throughout the service |
| keldor | 7.3.0 | http-framework | Groupon internal templating / view rendering engine |
| itier-user-auth | 8.1.0 | auth | User authentication and session middleware |
| itier-divisions | 7.0.2 | state-management | In-process division/locale data management |
| gofer | 2.1.0 | http-client | Base HTTP client for upstream API calls |
| preact | 10.0.4 | ui-framework | React-compatible component rendering (SSR + client) |
| tracking-hub-node | 1.11.0 | metrics | Emits enrollment and membership tracking events to Tracking Hub |
| webpack | 4.34.0 | build | Client-side asset bundling |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
