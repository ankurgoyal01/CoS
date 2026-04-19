---
service: "coupons-itier-global"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCouponsItierGlobalService", "continuumCouponsRedisCache"]
---

# Architecture Context

## System Context

`coupons-itier-global` is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It operates in the I-Tier layer, which handles server-side rendering and API orchestration for consumer-facing pages. The service receives traffic from end-user browsers via Akamai CDN and depends on two primary external data sources: Vouchercloud API for coupon/merchant/category data and GAPI (GraphQL) for deal and redemption data. Redis provides low-latency caching between the service and those backends.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Coupons I-Tier Global Service | `continuumCouponsItierGlobalService` | Application | Node.js / I-Tier | I-Tier (Node.js) service for coupons pages, APIs, and affiliate redirects |
| Coupons I-Tier Redis Cache | `continuumCouponsRedisCache` | Data Store | Redis | Shared cache for coupon offers, redirects, and derived render payloads |

## Components by Container

### Coupons I-Tier Global Service (`continuumCouponsItierGlobalService`)

| Component | ID | Responsibility | Technology |
|-----------|-----|---------------|-----------|
| I-Tier Server | `itierServer` | Handles HTTP requests, server-side rendering, and route orchestration | Node.js / itier-server |
| GAPI Client | `couponsItierGlobal_gapiClient` | Fetches deal and redemption data from GAPI | HTTP client / @grpn/graphql-gapi |
| Vouchercloud Client | `couponsItierGlobal_vouchercloudClient` | Fetches coupon, merchant, and category data from Vouchercloud | HTTP client / @grpn/voucher-cloud-client |
| Cache Client | `couponsItierGlobal_cacheClient` | Caches responses and redirect rules in Redis | ioredis / itier-cached |
| Redirect Cache Cron | `redirectCacheCron` | Periodically refreshes redirect rules in Redis | Node.js cron / node-schedule |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `itierServer` | `couponsItierGlobal_gapiClient` | Requests deals and redemption data | Internal |
| `itierServer` | `couponsItierGlobal_vouchercloudClient` | Fetches offers, merchants, and redirects | Internal |
| `itierServer` | `couponsItierGlobal_cacheClient` | Reads and writes cached payloads | Internal |
| `redirectCacheCron` | `couponsItierGlobal_vouchercloudClient` | Refreshes redirect rules | Internal |
| `redirectCacheCron` | `couponsItierGlobal_cacheClient` | Stores redirect cache entries | Internal |
| `couponsItierGlobal_cacheClient` | `continuumCouponsRedisCache` | Reads/writes cached data | Redis |
| `continuumCouponsItierGlobalService` | `continuumCouponsRedisCache` | Caches offer and redirect data | Redis |

## Architecture Diagram References

- Component view: `CouponsItierGlobalComponents`
- Dynamic views: No dynamic views captured yet (see `views/dynamics.dsl`)
