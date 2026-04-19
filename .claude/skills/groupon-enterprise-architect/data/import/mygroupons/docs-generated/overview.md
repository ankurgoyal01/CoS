---
service: "mygroupons"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Post-purchase / Redemption"
platform: "Continuum"
team: "Redemption Engineering"
status: active
tech_stack:
  language: "Node.js"
  language_version: "20.11.0"
  framework: "Express"
  framework_version: "4.14"
  runtime: "Node.js"
  runtime_version: "20.11.0"
  build_tool: "Webpack"
  build_tool_version: "4.41.2"
  package_manager: "npm"
---

# My Groupons Overview

## Purpose

My Groupons is the post-purchase hub that lets Groupon customers view and manage all their purchased deals. It acts as a stateless Backend-for-Frontend (BFF), orchestrating calls to multiple downstream Continuum services to render voucher details, generate PDF vouchers via headless Chromium, and handle post-purchase actions including returns, exchanges, gifting, and order tracking.

## Scope

### In scope

- Rendering the main "My Groupons" deal list page (`/mygroupons`)
- Serving individual voucher detail pages (`/mygroupons/vouchers/:id`)
- Generating and delivering PDF voucher downloads via Puppeteer/Chromium (`/mygroupons/vouchers/:id/pdf`)
- Handling return request submission (`/mygroupons/returns`)
- Handling voucher exchange flows (`/mygroupons/exchanges`)
- Sending voucher gifts to recipients (`/mygroupons/gifting`)
- Displaying order shipment tracking (`/mygroupons/track-order/:id`)
- Displaying and managing Groupon Bucks balance (`/mygroupons/my-bucks`)
- Rendering account details editing page (`/mygroupons/account/details`)
- Server-side rendering via Preact with Mustache templating

### Out of scope

- Payment processing and order creation (handled by Orders Service)
- Deal catalog management (handled by Deal Catalog Service)
- Voucher inventory state management (handled by Voucher Inventory Service)
- User identity and authentication (handled by Users Service)
- Barcode generation logic (handled by Barcode Service)
- Page layout and navigation chrome (handled by Layout Service)

## Domain Context

- **Business domain**: Post-purchase / Redemption
- **Platform**: Continuum
- **Upstream consumers**: End-user browsers (via Akamai/API Proxy); internal Groupon web clients
- **Downstream dependencies**: `apiProxy`, `continuumOrdersService`, `continuumDealCatalogService`, `continuumUsersService`, `continuumVoucherInventoryService`, `continuumRelevanceApi`, `gims`, `continuumThirdPartyInventoryService`, Barcode Service, Layout Service

## Stakeholders

| Role | Description |
|------|-------------|
| Redemption Engineering | Service owner; responsible for development and operations |
| Product — Post-purchase | Defines feature scope for the My Groupons experience |
| Customer Support | Relies on returns and exchange flows to support customers |
| End users (customers) | Primary consumers of the My Groupons UI and PDF vouchers |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Node.js | 20.11.0 | `.nvmrc` / `package.json` engines |
| Framework | Express | 4.14 | `package.json` dependencies |
| Server framework | itier-server | 7.14.2 | `package.json` dependencies |
| Build tool | Webpack | 4.41.2 | `package.json` devDependencies |
| Package manager | npm | — | `package-lock.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `express` | 4.14 | http-framework | HTTP routing and middleware |
| `itier-server` | 7.14.2 | http-framework | Groupon itier server scaffold for Express |
| `preact` | 10.5.14 | ui-framework | Server-side rendering of UI components |
| `webpack` | 4.41.2 | build-tool | Client-side asset bundling |
| `puppeteer` | 10.4 | pdf-generation | Headless Chromium for PDF voucher rendering |
| `itier-groupon-v2-mygroupons` | 3.2.4 | http-client | Client library for My Groupons data API |
| `itier-groupon-v2-orders` | 2.0.1 | http-client | Client library for Orders API |
| `gofer` | 4.1.0 | http-client | HTTP client for downstream service calls |
| `keldor` | 7.3.9 | auth | Groupon session/auth middleware |
| `async` | 0.9.2 | utility | Async control flow (parallel/waterfall) |
| `mustache` | 2.3.0 | templating | HTML template rendering |
| `itier-instrumentation` | 9.13.4 | metrics | Service instrumentation and metrics emission |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
