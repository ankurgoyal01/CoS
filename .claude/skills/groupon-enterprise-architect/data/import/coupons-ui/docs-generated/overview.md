---
service: "coupons-ui"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Coupons"
platform: "Continuum"
team: "Coupons"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "5.9"
  framework: "Astro"
  framework_version: "5.13"
  runtime: "Node.js"
  runtime_version: "22"
  build_tool: "pnpm"
  package_manager: "pnpm 10.15.1"
---

# Coupons UI Overview

## Purpose

Coupons UI is an Astro-based server-side-rendered web application that provides Groupon users with access to discount codes, deals, and special offers from popular retailers and brands. It composes merchant coupon pages by fetching pre-cached offer data from Redis and delegates redemption and redirect operations to the VoucherCloud API. The service covers 11 country markets (US, GB, AU, DE, FR, ES, IT, IE, NL, PL, AE) with locale-aware URL schemes and content.

## Scope

### In scope

- SSR merchant coupon pages displaying active and expired offers per country
- Client-side redemption orchestration (modal display, code reveal, affiliate link opening)
- Affiliate redirect URL resolution via VoucherCloud API
- Algolia-powered merchant search widget
- Google Tag Manager injection for analytics
- Structured request logging and metrics emission via Telegraf/InfluxDB
- Multi-region, multi-country URL routing and SEO metadata generation

### Out of scope

- Coupon data ingestion and cache population (handled by an upstream worker/pipeline that writes to Redis)
- User authentication and account management
- Payment processing
- Groupon Deals (local commerce) — separate product surface
- VoucherCloud platform operations

## Domain Context

- **Business domain**: Coupons
- **Platform**: Continuum
- **Upstream consumers**: End users via browser; nginx reverse proxy routes `/coupons/*` traffic to the Node.js server
- **Downstream dependencies**: VoucherCloud API (redemption, redirects), Redis (cached merchant and site-wide coupon data), Algolia (merchant search), Google Tag Manager (analytics)

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering team | Coupons team (coupons-eng@groupon.com); owner: c_marustamyan |
| SRE / On-call | Alerts sent to coupons-alerts@groupon.com |
| Confluence space | https://confluence.groupondev.com/display/COUP/Coupons |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.9 | `package.json` |
| Framework | Astro | 5.13 | `package.json`, `astro.config.mjs` |
| UI components | Svelte | 5.39 | `package.json`, `@astrojs/svelte ^7.1.1` |
| Runtime | Node.js | 22 (Alpine) | `Dockerfile` |
| Build tool | pnpm | 10.15.1 | `package.json` `packageManager` field |
| Reverse proxy | nginx | Alpine package | `Dockerfile`, `nginx.conf` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `astro` | ^5.13.10 | http-framework | SSR page rendering and API routes |
| `@astrojs/node` | ^9.4.4 | http-framework | Standalone Node.js adapter for Astro |
| `svelte` | ^5.39.5 | ui-framework | Interactive client-side components (coupon tiles, search, modals) |
| `ioredis` | ^5.8.0 | db-client | Redis client for cached merchant/site-wide data reads |
| `got` | ^14.6.2 | http-framework | HTTP client for VoucherCloud API calls with retry/timeout support |
| `algoliasearch` | ^5.46.0 | http-framework | Algolia JS client for merchant search widget |
| `node-cache` | ^5.1.2 | db-client | Process-local in-memory cache buffering site-wide data |
| `js-yaml` | ^4.1.0 | serialization | YAML config file parsing |
| `influx` | ^5.11.0 | metrics | InfluxDB/Telegraf metrics emission |
| `uuid` | ^13.0.0 | serialization | Request ID generation |
| `tailwindcss` | ^4.1.12 | ui-framework | Utility-first CSS styling |
| `vitest` | ^4.0.13 | testing | Unit test runner |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for a full list.
