---
service: "mdi-dashboard-v3"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Marketing Deal Insights"
platform: "Continuum"
team: "MIS Engineering"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2020+"
  framework: "Itier"
  framework_version: "7.7.2"
  runtime: "Node.js"
  runtime_version: "14.x (^14.16.1)"
  build_tool: "Webpack"
  package_manager: "npm"
---

# MDI Dashboard V3 Overview

## Purpose

MDI Dashboard V3 (Marketing Deal Insights Dashboard) is an internal web application that provides Groupon operators, merchandisers, and analysts with tooling to diagnose deal health, explore relevance API results, inspect and manage deal clusters, review feed pipeline status, and analyse merchant performance. It aggregates data from multiple downstream Continuum services and renders it in a unified, navigable dashboard, removing the need for internal users to query backend APIs directly.

## Scope

### In scope

- Deal browsing and search with multi-dimensional filters (country, channel, division, margin, price, location radius)
- Deal detail inspection including attributes, refresh triggers, and ad-inventory booster updates
- Sales performance charting for individual deals (purchases, views, activations) across configurable time spans
- Cluster (deal grouping) list, detail, and history views with performance graphs
- Relevance API (RAPI) query builder and result inspector with debug mode support
- Feed listing, batch expansion, upload-batch inspection, and dispatcher status
- Merchant insights: top-city analysis and cluster performance breakdowns per merchant

### Out of scope

- Deal creation or editing (owned by `continuumMarketingDealService`)
- Voucher fulfilment and inventory management (owned by `continuumVoucherInventoryService`)
- Ad campaign management beyond booster status updates (owned by `continuumAdInventoryService`)
- Consumer-facing search or deal discovery

## Domain Context

- **Business domain**: Marketing Deal Insights
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon operators and merchandisers (browser-based); no machine-to-machine callers documented
- **Downstream dependencies**: `continuumMarketingDealService`, `continuumRelevanceApi`, `continuumApiLazloService`, `apiProxy`, `continuumDealCatalogService`, `continuumVoucherInventoryService`, `continuumAdInventoryService`, Salesforce (deep-link generation), Deals Cluster Service, MDS Feed Service, Deal Performance Service V2, LPAPI (location autocomplete)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | dgundu (MIS Engineering) |
| Engineering Team | MIS Engineering — rsolanki, visj, dgundu |
| Operations Contact | mis-engineering@groupon.com |
| PagerDuty | https://groupon.pagerduty.com/services/P48UMW7 |
| Slack | #C01329P1GFM |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (ESM + CJS) | ES2020+ | `package.json` scripts, `.mjs` modules |
| Framework | Itier | 7.7.2 | `package.json` — `itier-server: ^7.7.2` |
| Config framework | Keldor | 7.3.9 | `package.json` — `keldor: ^7.3.9` |
| Runtime | Node.js | ^14.16.1 | `package.json` `engines.node` |
| Build tool | Webpack | 5.40.0 | `package.json` devDependencies |
| Package manager | npm | — | `package-lock.json` present |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `itier-server` | ^7.7.2 | http-framework | Core HTTP server and route wiring |
| `keldor` | ^7.3.9 | http-framework | Configuration-driven route and config management |
| `keldor-config` | ^4.23.2 | config | Keldor remote config loading |
| `preact` | ^10.5.13 | ui-framework | Lightweight React-compatible UI rendering |
| `@material-ui/core` | ^4.12.3 | ui-framework | Component library for dashboard UI |
| `chart.js` | ^3.5.1 | ui-framework | Performance charting (purchases, views, activations) |
| `react-chartjs-2` | ^3.0.5 | ui-framework | Chart.js bindings for Preact/React |
| `gofer` | ^5.2.0 | http-client | HTTP client for service-to-service calls |
| `node-fetch` | ^3.0.0 | http-client | Fetch-based HTTP for server-side API actions |
| `itier-tracing` | ^1.6.1 | tracing | Distributed tracing integration |
| `itier-instrumentation` | ^9.13.4 | metrics | Service metrics emission (SMA/Wavefront) |
| `itier-feature-flags` | ^2.2.2 | config | Runtime feature flag evaluation |
| `formik` | ^2.2.9 | validation | Form state management |
| `yup` | ^0.32.9 | validation | Schema-based form validation |
| `date-fns` | ^2.28.0 | serialization | Date formatting and arithmetic for performance spans |
| `itier-user-auth` | ^8.0.4 | auth | User authentication middleware |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for the full list.
