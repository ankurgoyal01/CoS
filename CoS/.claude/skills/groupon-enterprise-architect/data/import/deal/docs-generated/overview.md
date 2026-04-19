---
service: "deal"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Commerce / Funnel"
platform: "continuum"
team: "Funnel / Consumer Experience (funnel-dev@groupon.com)"
status: active
tech_stack:
  language: "Node.js"
  language_version: "16.16.0"
  framework: "Express.js / itier-server"
  framework_version: "4.17.1 / 7.14.2"
  runtime: "Node.js"
  runtime_version: "16"
  build_tool: "Webpack 4.46.0, npm"
  package_manager: "npm"
---

# Deal Page Overview

## Purpose

The deal service is a server-side rendered (SSR) Node.js web application that delivers deal pages to Groupon consumers. It aggregates data from multiple backend APIs — including deal metadata, pricing, merchant details, and availability — and renders a unified page experience across web and mobile channels. The service operates as a stateless I-Tier front-end node within the Continuum platform, delegating all data persistence to downstream services.

## Scope

### In scope

- Server-side rendering of deal detail pages (prices, merchant info, availability, booking UI)
- Serving static assets for the deal page bundle
- Handling internal AJAX requests via `POST /deals/api/*`
- Assembling and coordinating parallel API calls to backend services (deal data, pricing, merchant, cart, wishlists)
- A/B test variant assignment and feature flag evaluation at render time
- Wishlist page rendering
- AMP (Accelerated Mobile Pages) variant rendering
- Online booking and appointment availability display

### Out of scope

- Deal catalog management and deal data storage (handled by Deal Catalog service)
- Payment processing and order creation (handled by Orders / Cart services)
- Merchant onboarding and data management (handled by M3/Merchant services)
- Availability slot management (handled by Availability Engine / Online Booking Service)
- User authentication and session management (handled by upstream auth layer)

## Domain Context

- **Business domain**: Commerce / Funnel
- **Platform**: continuum (I-Tier)
- **Upstream consumers**: Groupon web browsers, Groupon mobile apps, Akamai CDN/edge layer
- **Downstream dependencies**: Groupon V2 Client (deal, pricing, merchant, cart, wishlists), MapProxy/Mapbox, GraphQL APIs, Experimentation Service, Online Booking Service, Gig Components

## Stakeholders

| Role | Description |
|------|-------------|
| Groupon Consumer | End user browsing and purchasing deals |
| Commerce / Funnel Team | Service owners responsible for deal page experience |
| Platform (I-Tier) Team | Owners of the itier-server framework used by this service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Node.js | 16.16.0 | package.json / .nvmrc |
| Framework | Express.js | 4.17.1 | package.json |
| Framework | itier-server | 7.14.2 | package.json |
| Runtime | Node.js | 16 | Docker base image |
| Build tool | Webpack | 4.46.0 | package.json |
| Package manager | npm | — | package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.14.2 | http-framework | I-Tier SSR server framework for Continuum |
| itier-groupon-v2-client | 4.2.5 | http-client | Client for Groupon V2 backend APIs (deals, pricing, merchant, cart) |
| keldor | 7.3.9 | http-framework | Internal routing/middleware layer |
| @grpn/design-system | 0.22.26 | ui-framework | Groupon shared UI component library |
| preact | 10.13.2 | ui-framework | Lightweight React-compatible rendering library |
| itier-instrumentation | 9.13.4 | metrics | Metrics and tracing instrumentation for I-Tier services |
| itier-render | 2.0.3 | http-framework | SSR rendering utilities for I-Tier |
| redux | 3.7.2 | state-management | Client-side state management for deal page |
| itier-feature-flags | 2.2.2 | validation | Feature flag evaluation at render time |
| @grpn/graphql | 4.1.1 | http-client | GraphQL API client for Groupon services |
| zustand | 4.3.7 | state-management | Lightweight client-side state management |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
