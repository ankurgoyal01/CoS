---
service: "sponsored-campaign-itier"
title: Overview
generated: "2026-03-02"
type: overview
domain: "E-commerce / Advertising / Sponsored Campaigns"
platform: "Continuum"
team: "ads (Ad-Inventory team)"
status: active
tech_stack:
  language: "TypeScript/JavaScript"
  language_version: "ES2020"
  framework: "itier-server"
  framework_version: "7.9.2"
  runtime: "Node.js"
  runtime_version: "20.19.5"
  build_tool: "webpack 4.46.0 / napistrano 2.180.3"
  package_manager: "npm"
---

# Sponsored Campaign iTier Overview

## Purpose

`sponsored-campaign-itier` is a Backend-for-Frontend (BFF) service that enables Groupon merchants to manage sponsored campaign promotions through Groupon's Merchant Center. It serves a React/Redux single-page application and proxies all campaign, billing, and performance operations to upstream services — principally UMAPI (Universal Merchant API) — without owning any persistent state itself. The service also handles server-side rendering of merchant UI pages and enforces merchant authentication on every request.

## Scope

### In scope

- Serving the Merchant Center sponsored campaign UI (React/Preact SPA) at `/merchant/center/sponsored/campaign/*`
- Proxying campaign CRUD operations (create, update, delete, status toggle) to UMAPI
- Proxying billing record management (create, update, delete payment methods) to UMAPI via Groupon V2 client
- Proxying wallet top-up and refund operations to UMAPI
- Proxying performance metric retrieval (impressions, clicks, spend, ROAS) from UMAPI
- Merchant session authentication via `itier-user-auth` on every inbound request
- Feature flag evaluation (via Birdcage/itier-feature-flags) to gate campaign capabilities
- Server-side rendering of React pages with initial Redux state injection

### Out of scope

- Storing campaign, billing, or performance data — all persistence is owned by UMAPI and Groupon V2
- Business logic for campaign eligibility or pricing — enforced in UMAPI
- Merchant identity management — owned by `continuumMerchantApi`
- Geographic location data — owned by `continuumGeoDetailsService`
- Direct consumer-facing (shopper) flows — this service is strictly merchant-facing

## Domain Context

- **Business domain**: E-commerce / Advertising / Sponsored Campaigns
- **Platform**: Continuum
- **Upstream consumers**: Groupon Merchant Center (browser, merchants) at `https://www.groupon.com/merchant/center/sponsored`
- **Downstream dependencies**: UMAPI (`continuumUniversalMerchantApi`), Merchant API (`continuumMerchantApi`), GeoDetails Service (`continuumGeoDetailsService`), Birdcage feature flags (`continuumBirdcageService`)

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | ushankarprasad — primary engineering owner |
| Engineering team | Ad-Inventory team (`ads`) — ads-eng@groupon.com |
| PagerDuty | https://groupon.pagerduty.com/services/PS4HL4Y |
| Merchant users | Groupon merchants who manage sponsored promotions via Merchant Center |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript/JavaScript | ES2020 | tsconfig.json target |
| Framework | itier-server | 7.9.2 | package.json |
| Runtime | Node.js | 20.19.5 | .nvmrc, Dockerfile (alpine-node20.19.5) |
| Build tool | webpack | 4.46.0 | package.json |
| Build/deploy | napistrano | 2.180.3 | package.json |
| Package manager | npm | | package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | ^7.9.2 | http-framework | Groupon's Node.js web server framework |
| React | ^17.0.1 | ui-framework | Frontend UI SPA library |
| Redux | ^4.0.5 | state-management | Centralized UI state management |
| axios | ^0.21.1 | http-client | HTTP client for API proxy calls |
| @grpn/mx-api | ^1.1.0 | http-framework | Groupon unified HTTP client |
| @grpn/mx-merchant | ^7.1.3 | other | Merchant-specific utilities and middleware |
| itier-instrumentation | ^9.10.4 | metrics | Distributed tracing via Tracky/Grout |
| itier-feature-flags | ^3.2.0 | other | Feature flag evaluation |
| itier-groupon-v2-client | ^4.2.4 | db-client | Client for Groupon V2/UMAPI billing services |
| itier-merchant-api-client | ^1.1.3 | http-client | Merchant-specific API operations |
| itier-user-auth | ^8.1.0 | auth | Merchant session validation |
| @grpn/graphql | ^4.1.1 | http-client | GraphQL client for backend services |
| Preact | ^10.5.13 | ui-framework | Lightweight React alternative for SSR |
| mocha | ^9.0.1 | testing | Test runner |
| c8 | ^7.7.3 | testing | Code coverage |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
