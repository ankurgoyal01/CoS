---
service: "pricing-control-center-ui"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Dynamic Pricing"
platform: "Continuum"
team: "Dynamic Pricing"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2020 (Node.js ^16)"
  framework: "iTier / Keldor"
  framework_version: "keldor ^7.3.7, itier-server ^7.7.2"
  runtime: "Node.js"
  runtime_version: "^16 (alpine-node16.16.0 Docker base)"
  build_tool: "Webpack 5 / Napistrano"
  package_manager: "npm ^8"
---

# Pricing Control Center UI Overview

## Purpose

Pricing Control Center UI is an internal Node.js web application that provides the Dynamic Pricing team with a browser-based control plane for managing pricing sales across Groupon's commerce platform. It serves server-rendered Preact pages and acts as a thin API gateway — routing authenticated user actions (sale creation, CSV uploads, sale scheduling/cancellation, product searches) through to the pricing-control-center-jtier backend service. The application enforces authentication via Doorman SSO and restricts access to authorised internal operators.

## Scope

### In scope

- Serving authenticated HTML pages for all Pricing Control Center workflows (home, search, sale management, upload)
- Proxying authenticated API calls to `pricing-control-center-jtier` via HBProxyClient
- Handling Doorman SSO authentication redirect and token handoff (`/doorman`, `/post-user-auth-token`)
- Accepting and forwarding multipart CSV uploads for ILS (Inventory and Listing Service) price data
- Providing a CSV download route for existing sale data
- Rendering sale lifecycle actions: schedule, unschedule, cancel, retry stuck sales
- Surfacing exclusion reasons and progress counts for sale detail views

### Out of scope

- Pricing computation or business logic (owned by `pricing-control-center-jtier`)
- Direct database access (all data is fetched from the jtier API)
- Consumer-facing (public) product pricing display
- Publishing or consuming Kafka/message-bus events

## Domain Context

- **Business domain**: Dynamic Pricing
- **Platform**: Continuum
- **Upstream consumers**: Internal pricing team operators via web browser; Hybrid Boundary ingress routes (`control-center.groupondev.com`, `control-center--staging.groupondev.com`)
- **Downstream dependencies**: `pricing-control-center-jtier` (all pricing data and operations); Doorman SSO (authentication initiation and token validation)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | abhsinha (Dynamic Pricing team) |
| Engineering Team | Dynamic Pricing — dp-engg@groupon.com |
| SRE Contact | GChat space `AAAAi3yfoYY` |
| Primary Users | Internal Dynamic Pricing operators managing sale schedules and pricing uploads |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js) | ^16 | `package.json` engines field |
| Web Framework | iTier / Keldor | itier-server ^7.7.2, keldor ^7.3.7 | `package.json` dependencies |
| UI Framework | Preact | ^10.5.13 | `package.json` dependencies |
| Build tool | Webpack | ^5.72.1 | `package.json` devDependencies |
| Package manager | npm | ^8.13.2 | `package.json` dependencies |
| Container base | alpine-node16.16.0 | 2022.07.22 | `Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `keldor` | ^7.3.7 | http-framework | Core iTier application server and dependency injection container |
| `itier-server` | ^7.7.2 | http-framework | Groupon iTier server bootstrap for Node.js web apps |
| `@grpn/hb-proxy-client` | ^1.0.3 | http-client | HybridBoundary-aware HTTP client for calling internal services |
| `@grpn/graphql` | ^4.0.0 | http-client | GraphQL client integration for iTier applications |
| `itier-user-auth` | ^8.1.0 | auth | User authentication middleware for iTier (Doorman token validation) |
| `@grpn/promise-actions` | ^4.2.1 | http-framework | Action-based request/response helpers (redirect, json) |
| `preact` | ^10.5.13 | ui-framework | Lightweight React-compatible UI library for server-rendered pages |
| `@grpn/preact-page` | ^2.4.2 | ui-framework | Preact server-side page composition helper for iTier |
| `itier-routing` | ^5.1.7 | http-framework | Route registration and URL builder for iTier applications |
| `multer` | ^1.4.5-lts.1 | http-framework | Multipart form/file upload middleware for CSV upload proxy |
| `itier-feature-flags` | ^2.2.2 | configuration | Feature flag client for runtime feature toggling |
| `itier-instrumentation` | ^9.10.4 | metrics | Metrics and instrumentation for Wavefront/InfluxDB |
| `date-fns` | ^2.29.3 | utility | Date formatting and timezone manipulation for sale scheduling |
| `gofer` | ^5.2.2 | http-client | Base HTTP client library underlying HBProxyClient calls |
