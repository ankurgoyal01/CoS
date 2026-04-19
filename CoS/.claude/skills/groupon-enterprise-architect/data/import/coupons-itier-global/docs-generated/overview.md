---
service: "coupons-itier-global"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Coupons / Affiliate Commerce"
platform: "Continuum"
team: "Coupons (coupons-eng@groupon.com)"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "Node.js 14.19.3"
  framework: "I-Tier/Express"
  framework_version: "4.18.2"
  runtime: "Node.js"
  runtime_version: "14.19.3"
  build_tool: "Webpack"
  build_tool_version: "5.73.0"
  package_manager: "npm"
---

# Coupons I-Tier Global Overview

## Purpose

`coupons-itier-global` is Groupon's global coupons discovery and redemption platform, serving consumers across 11 countries. It renders coupon browsing pages, handles affiliate merchant and offer redirects, and orchestrates data from Vouchercloud and GAPI (GraphQL API) to deliver deal content. The service sits in the Continuum I-Tier layer, providing both server-side rendered UI and REST API endpoints.

## Scope

### In scope

- Server-side rendering of coupons browsing pages (`/coupons`, `/category/{category}`)
- Affiliate redirect resolution for merchants (`/redirect/merchant/{id}`) and offers (`/redirect/offers/{id}`)
- Fetching and caching coupon, merchant, and category data from Vouchercloud API
- Fetching deal and redemption data from GAPI (GraphQL)
- Periodic refresh of redirect rules stored in Redis via a cron job
- GraphQL explorer endpoint (`/graphiql`) for development introspection

### Out of scope

- Deal creation and inventory management (handled by Continuum deal services)
- Payment and order processing (handled by Continuum order/payment services)
- User authentication and session management (handled by upstream I-Tier platform)
- Vouchercloud data ingestion and indexing (owned by Vouchercloud systems)

## Domain Context

- **Business domain**: Coupons / Affiliate Commerce
- **Platform**: Continuum
- **Upstream consumers**: End-user browsers (via Akamai CDN), Layout Service, Groupon V2 Services
- **Downstream dependencies**: Vouchercloud API, GAPI (GraphQL), Redis Cache (`continuumCouponsRedisCache`)

## Stakeholders

| Role | Description |
|------|-------------|
| Coupons Engineering Team | Service owner; contact coupons-eng@groupon.com |
| Coupon consumers (end users) | Browse and redeem coupon offers across 11 countries |
| Affiliate merchants | Destination of redirect flows initiated from this service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | Node.js 14.19.3 | `package.json` / `engines` field |
| Framework | I-Tier/Express | 4.18.2 | `package.json` dependency `express` |
| Runtime | Node.js | 14.19.3 | `package.json` / `.nvmrc` |
| Build tool | Webpack | 5.73.0 | `package.json` dependency `webpack` |
| Package manager | npm | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `itier-server` | 7.14.2 | http-framework | I-Tier server bootstrap: routing, SSR, middleware |
| `preact` | 10.5.13 | ui-framework | Lightweight React-compatible UI rendering |
| `ioredis` | 5.7.0 | db-client | Redis client for offer, redirect, and render payload caching |
| `axios` | 1.5.1 | http-framework | HTTP client for Vouchercloud and GAPI requests |
| `@grpn/graphql-gapi` | 5.2.9 | http-framework | Groupon GAPI GraphQL client for deal and redemption data |
| `@grpn/voucher-cloud-client` | 1.50.4 | http-framework | Vouchercloud API client for coupon, merchant, and category data |
| `itier-feature-flags` | 3.3.0 | validation | I-Tier feature flag evaluation |
| `redux` | 4.0.1 | state-management | Client-side and server-side state management |
| `influx` | 5.10.0 | metrics | InfluxDB client for operational metrics reporting |
| `node-schedule` | 2.1.1 | scheduling | Cron scheduler driving the redirect cache refresh job |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
