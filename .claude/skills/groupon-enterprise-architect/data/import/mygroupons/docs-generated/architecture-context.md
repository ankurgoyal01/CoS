---
service: "mygroupons"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumMygrouponsService]
---

# Architecture Context

## System Context

My Groupons (`continuumMygrouponsService`) is a consumer-facing BFF within the **Continuum** platform. It sits between the end-user browser and a set of internal Continuum services, aggregating data from orders, voucher inventory, deal catalog, user accounts, and relevance APIs to compose the post-purchase experience. All inbound traffic passes through `apiProxy`, which handles routing and authentication concerns before requests reach My Groupons.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| My Groupons Service | `continuumMygrouponsService` | Web Application / BFF | Node.js, Express, Preact | 20.11.0 / 4.14 / 10.5.14 | Stateless BFF that orchestrates post-purchase voucher, return, exchange, gifting, and account pages |

## Components by Container

### My Groupons Service (`continuumMygrouponsService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `myGroupons_requestOrchestration` | Orchestrates parallel downstream calls to compose page data for each route; manages async fan-out and error aggregation | Node.js async, Gofer HTTP client |
| Route handlers | Map each Express route to an orchestration pipeline; enforce auth via keldor middleware | Express 4.14, keldor 7.3.9 |
| PDF renderer | Launches headless Chromium via Puppeteer to render and stream PDF vouchers | Puppeteer 10.4, Chromium (alpine-node20) |
| SSR engine | Renders Preact components server-side and hydrates the Mustache shell template | Preact 10.5.14, Mustache 2.3.0 |
| Instrumentation | Emits latency, error-rate, and throughput metrics for all routes and downstream calls | itier-instrumentation 9.13.4 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMygrouponsService` | `apiProxy` | Routes outbound downstream calls through central API proxy | REST/HTTP |
| `continuumMygrouponsService` | `continuumOrdersService` | Fetches order and voucher data for the My Groupons page and voucher detail views | REST/HTTP |
| `continuumMygrouponsService` | `continuumDealCatalogService` | Retrieves deal metadata and redemption instructions for voucher pages | REST/HTTP |
| `continuumMygrouponsService` | `continuumUsersService` | Resolves user identity and account details; validates session | REST/HTTP |
| `continuumMygrouponsService` | `continuumVoucherInventoryService` | Reads and mutates voucher state (redeem, exchange, return eligibility) | REST/HTTP |
| `continuumMygrouponsService` | `continuumRelevanceApi` | Fetches personalized recommendations shown on the My Groupons page | REST/HTTP |
| `continuumMygrouponsService` | `gims` | Retrieves geographic and merchant information for deal display | REST/HTTP |
| `continuumMygrouponsService` | `continuumThirdPartyInventoryService` | Checks third-party inventory availability for exchanges and tracking | REST/HTTP |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-mygroupons`
