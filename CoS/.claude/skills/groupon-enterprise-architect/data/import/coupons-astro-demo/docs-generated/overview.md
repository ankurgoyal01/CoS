---
service: "coupons-astro-demo"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Coupons / Merchant Discovery"
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
  package_manager: "pnpm"
---

# Coupons Astro Demo Overview

## Purpose

`coupons-astro-demo` is a server-side rendered web application that renders coupon and merchant deal pages for Groupon's coupons product. It fetches pre-cached merchant data, active offers, advertisements, and SEO meta content from a Redis cache (populated by VoucherCloud) and assembles a complete page response on each request. The service is a proof-of-concept and demo for the Astro-based coupons frontend architecture on the Continuum platform.

## Scope

### In scope

- Serving the merchant coupons landing page at `/coupons/[merchantPermalink]`
- Reading merchant details, active offers, expired offers, adverts, similar merchants, top merchants, and SEO meta content from Redis
- Rendering a sidebar-and-main-content layout using Svelte island components
- Filtering and categorizing offers client-side (deals, codes, sales, rewards)
- Displaying advertisement carousels sourced from VoucherCloud advert data
- Providing SEO-ready page titles and meta descriptions from merchant meta content

### Out of scope

- Writing or populating the Redis cache (handled by VoucherCloud pipeline)
- Order processing or checkout
- User authentication or personalization
- Coupon redemption tracking
- Payment flows

## Domain Context

- **Business domain**: Coupons / Merchant Discovery
- **Platform**: Continuum
- **Upstream consumers**: End users via browser; Googlebot and other search engine crawlers (SSR delivers full HTML)
- **Downstream dependencies**: VoucherCloud Redis cache (read-only); no other runtime dependencies

## Stakeholders

| Role | Description |
|------|-------------|
| Coupons Engineering | Owns and develops the service; primary on-call |
| SEO / Growth | Consumes SSR-rendered HTML for organic search ranking |
| Merchant Partners | Indirect beneficiaries; offers and logos surface on their pages |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.9 | `package.json` |
| Framework | Astro | 5.13 | `package.json`, `astro.config.mjs` |
| Runtime | Node.js | 22 | `Dockerfile`, `.nvmrc` (v22.14.0) |
| Build tool | pnpm | 10.12.1 | `Dockerfile` (`corepack prepare pnpm@10.12.1`) |
| Package manager | pnpm | 10.x | `pnpm-lock.yaml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `astro` | ^5.13.7 | http-framework | SSR page routing, middleware pipeline, server adapter |
| `@astrojs/node` | ^9.4.3 | http-framework | Node.js standalone server adapter for Astro SSR |
| `@astrojs/svelte` | ^7.1.1 | ui-framework | Svelte integration for interactive island components |
| `svelte` | ^5.38.8 | ui-framework | Component framework for client-side interactive UI islands |
| `ioredis` | ^5.7.0 | db-client | Redis client for reading VoucherCloud-cached merchant data |
| `tailwindcss` | ^4.1.13 | ui-framework | Utility-first CSS framework for page styling |
| `@tailwindcss/vite` | ^4.1.13 | ui-framework | Vite plugin enabling Tailwind CSS v4 in the Astro build |
