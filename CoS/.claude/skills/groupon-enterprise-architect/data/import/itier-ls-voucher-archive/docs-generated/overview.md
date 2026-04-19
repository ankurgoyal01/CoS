---
service: "itier-ls-voucher-archive"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Interaction Tier / Web Frontend"
platform: "Continuum"
team: "Continuum / LivingSocial Migration"
status: active
tech_stack:
  language: "JavaScript/CoffeeScript"
  language_version: "ES5/CoffeeScript"
  framework: "Express + itier-server"
  framework_version: "Express 4.14 / itier-server 5.36.5"
  runtime: "Node.js"
  runtime_version: "10.x"
  build_tool: "webpack"
  build_tool_version: "4"
  package_manager: "npm"
---

# LivingSocial Voucher Archive Interaction Tier Overview

## Purpose

itier-ls-voucher-archive is the web-facing interaction tier that serves legacy LivingSocial voucher pages to consumers, Customer Service Representatives (CSRs), and merchants. It renders voucher detail views, supports voucher printing as PDF, enables CSR refund operations, and provides merchant-facing voucher search and export capabilities. The service exists to maintain continuity of voucher redemption and service history for LivingSocial deals that predate the Groupon platform migration.

## Scope

### In scope

- Rendering consumer-facing voucher detail and archive pages for legacy LivingSocial vouchers
- Providing PDF-printable voucher views
- Exposing CSR routes for voucher refund and service operations (`/ls_voucher_archive/csrs/...`)
- Exposing merchant routes for voucher search and CSV export (`/ls_voucher_archive/merchants/...`)
- Applying user authentication via `itier-user-auth` and CSRF protection via `csurf`
- Localization and geo-based content selection via Bhuvan integration
- Caching rendered responses in Memcached to reduce backend API load
- Feature flag evaluation via `itier-feature-flags`

### Out of scope

- Voucher issuance or purchase flows (handled by Groupon commerce platform)
- LivingSocial deal discovery or browsing (separate services)
- Voucher redemption at point of sale (handled by merchant-facing tools)
- Backend voucher data storage and management (handled by Voucher Archive Backend)
- Authentication identity management (delegated to `itier-user-auth`)

## Domain Context

- **Business domain**: Interaction Tier / Web Frontend
- **Platform**: Continuum
- **Upstream consumers**: End users (consumers) via browser; CSR agents via internal tooling; merchant users via merchant portal
- **Downstream dependencies**: Voucher Archive Backend, Groupon v2 API (Lazlo / `continuumApiLazloService`), Universal Merchant API (`continuumUniversalMerchantApi`), Bhuvan geodetails service (`continuumBhuvanService`), API Proxy, Subscriptions API, GraphQL Gateway, Memcached (`continuumLsVoucherArchiveMemcache`)

## Stakeholders

| Role | Description |
|------|-------------|
| Consumers | End users viewing or printing legacy LivingSocial vouchers |
| CSR Agents | Customer service staff performing refunds and service operations |
| Merchants | Business owners searching and exporting voucher redemption data |
| Continuum Engineers | Develop and maintain the interaction tier |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript/CoffeeScript | ES5 / CoffeeScript | Source files |
| Framework | Express + itier-server | Express 4.14 / itier-server 5.36.5 | package.json |
| Runtime | Node.js | 10.x | package.json engines |
| Build tool | webpack | 4 | package.json devDependencies |
| Package manager | npm | — | package.json / package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 5.36.5 | http-framework | Groupon-standard interaction tier server wrapper; provides routing, middleware, and lifecycle management |
| express | 4.14 | http-framework | HTTP request routing and middleware pipeline |
| preact | 10.0.4 | ui-framework | Lightweight React-compatible UI rendering for server-side and client-side views |
| itier-user-auth | 7.0.0 | auth | Groupon standard user authentication middleware for interaction tiers |
| itier-feature-flags | 1.5.0 | validation | Feature flag evaluation at request time |
| keldor | 7.3.0 | http-framework | Groupon internal HTTP client for backend API calls |
| webpack | 4 | build | Client-side asset bundling |
| csurf | 1.6.4 | auth | CSRF token generation and validation middleware |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
