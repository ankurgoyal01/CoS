---
service: "coupons-astro-demo"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Coupons Astro Demo.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Page Request](merchant-page-request.md) | synchronous | HTTP GET /coupons/[merchantPermalink] | Full SSR render flow from browser request to HTML response, including all Redis data fetches |
| [Dependency Initialization](dependency-initialization.md) | synchronous | Every incoming HTTP request (middleware) | Initializes Redis and VoucherCloud client instances and injects them into request context |
| [Offer Filter](offer-filter.md) | synchronous | User interaction (client-side) | Client-side filtering of rendered offers by type (deal, code, sale, reward) using Svelte stores |
| [Redis Cache Read](redis-cache-read.md) | synchronous | Called by VoucherCloudClient methods | Key prefixing, JSON envelope unwrapping, and typed response extraction from Redis |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The merchant page request flow crosses the boundary between `continuumCouponsAstroWebApp` and the external `voucherCloudRedisCache`. The Redis cache is populated by an external VoucherCloud pipeline not modeled in this repository. See [Architecture Context](../architecture-context.md) for the stub relationship definition.
