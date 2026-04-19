---
service: "clo-ita"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Card Linked Offers (CLO)"
platform: "Continuum"
team: "clo-dev@groupon.com"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "18"
  framework: "Express"
  framework_version: "4.14.0"
  runtime: "Node.js"
  runtime_version: "18"
  build_tool: "Webpack"
  build_tool_version: "4.46.0"
  package_manager: "npm"
---

# CLO I-Tier Frontend Overview

## Purpose

`clo-ita` is the I-Tier (itier) BFF (Backend-for-Frontend) for Groupon's Card Linked Offers product. It serves all CLO-facing UI experiences — including deal claiming, card enrollment, consent management, transaction summaries, and missing cash-back support — by aggregating data from downstream Continuum platform services and exposing a unified HTTP interface consumed by the frontend layer. The service is stateless and owns no persistent data of its own; it acts purely as an orchestration and rendering layer.

## Scope

### In scope

- Rendering and serving the CLO claiming experience for individual deals (`/deals/:dealId/claim`)
- Proxying claim, bulk-claim, card enrollment, SMS consent, and related-deals requests to the CLO Backend API via a shared API proxy (`/clo/proxy/*`)
- Managing card enrollment and un-enrollment flows (`/clo/enrollment/*`)
- Displaying linked deals per user (`/users/:userId/linked-deals`)
- Displaying transaction summaries for CLO users (`/users/:userId/transaction_summary`)
- Handling missing cash-back support requests (`/clo/missing_cash_back/*`)
- Serving the CLO tutorial page (`/clo/tutorial`)
- Serving the consent cards page (`/clo/consent_cards`)
- Applying feature flags via `itier-feature-flags` to gate experiences
- Localization of UI content via `itier-localization`
- User authentication and session validation via `itier-user-auth`

### Out of scope

- Persistent storage of CLO claims or enrollment records (owned by CLO Backend API)
- Card linking with payment networks (owned by CLO Backend API and upstream card networks)
- Deal catalog management (owned by `continuumDealCatalogService`)
- User profile management (owned by `continuumUsersService`)
- Order and transaction record management (owned by `continuumOrdersService`)
- Geo-targeting logic (owned by `continuumGeoDetailsService`)

## Domain Context

- **Business domain**: Card Linked Offers (CLO)
- **Platform**: Continuum
- **Upstream consumers**: Groupon web and mobile frontend clients that render CLO UI experiences
- **Downstream dependencies**: `apiProxy` (CLO Backend API), `continuumMarketingDealService`, `continuumUsersService`, `continuumOrdersService`, `continuumGeoDetailsService`, `continuumDealCatalogService`

## Stakeholders

| Role | Description |
|------|-------------|
| Team | CLO engineering team (clo-dev@groupon.com) — owns development and operations |
| Product | CLO product team — defines claiming, enrollment, and cashback flows |
| Frontend clients | Web and mobile consumers of the I-Tier rendered pages |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | Node.js 18 | package.json / engines |
| Framework | Express | 4.14.0 | package.json dependencies |
| I-Tier server | itier-server | 7.14.2 | package.json dependencies |
| UI framework | Preact | 8.3.1 | package.json dependencies |
| Build tool | Webpack | 4.46.0 | package.json dependencies |
| Package manager | npm | — | package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-clo-client | 1.8.0 | http-framework | CLO-specific I-Tier client for downstream API calls |
| itier-groupon-v2-orders | — | http-framework | Adapter for Groupon V2 Orders Service |
| itier-groupon-v2-users | — | http-framework | Adapter for Groupon V2 Users Service |
| itier-groupon-v2-deals | — | http-framework | Adapter for Groupon V2 Deals Service |
| itier-feature-flags | 3.1.2 | feature-flags | Runtime feature flag evaluation |
| itier-localization | 10.3.0 | i18n | UI string localization |
| itier-user-auth | 8.1.0 | auth | User session authentication and validation |
| itier-cached | — | caching | Redis-backed response caching |
| body-parser | 1.7.0 | http-framework | HTTP request body parsing middleware |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
