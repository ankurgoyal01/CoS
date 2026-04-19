---
service: "coupons-astro-demo"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCouponsAstroWebApp]
---

# Architecture Context

## System Context

`coupons-astro-demo` is a container within the **Continuum Platform** (`continuumSystem`), Groupon's core commerce engine. It sits at the consumer-facing edge of the coupons domain, receiving HTTP requests from browsers and search-engine crawlers and returning fully server-rendered HTML. The application is read-only at runtime: it pulls pre-populated data from an external VoucherCloud Redis cache (`voucherCloudRedisCache`) and does not write to any data store. There are no upstream internal service calls; all data is sourced via Redis cache reads performed during SSR.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Coupons Astro Web App | `continuumCouponsAstroWebApp` | WebApp | Astro/Node.js | Astro 5.13, Node 22 | SSR application serving coupon and merchant pages |

## Components by Container

### Coupons Astro Web App (`continuumCouponsAstroWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Dependencies Middleware | Initializes `RedisClient` and `VoucherCloudClient` on every request; injects both into Astro `context.locals` for type-safe access downstream | TypeScript / Astro middleware |
| Merchant Coupons Route Handler | Handles `GET /coupons/[merchantPermalink]`; fetches all page data concurrently from VoucherCloud client; redirects to `/404` if merchant not found; passes data to UI components for rendering | Astro server route |
| VoucherCloud Client | Provides typed methods for reading merchant details, offers, adverts, similar merchants, top merchants, expired offers, and meta content from Redis; manages cache key composition and response shape validation | TypeScript |
| Redis Client | Wraps `ioredis` with country/locale-aware key prefixing (`vouchercloud:{COUNTRY}:{LOCALE}:groupon:{key}`); handles JSON parsing and the `d`-envelope data format used by VoucherCloud | TypeScript |
| UI Components | Svelte and Astro components that render the visible page: `OffersList`, `OfferCard`, `PremiumOfferCard`, `OfferFilter`, `AdvertCarousel`, `MerchantLogoContainer`, `StarRating`, `SidebarListMerchants`, `PopularOffers`, `ExpiredOfferCard`, `AlphabetNavigation`, `MerchantMetaContent` | Svelte / Astro |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `dependenciesMiddleware` | `redisClient_CouAstDem` | Creates and injects Redis client per request | direct (in-process) |
| `dependenciesMiddleware` | `voucherCloudClient` | Creates and injects VoucherCloud client per request | direct (in-process) |
| `couponsRouteHandler` | `voucherCloudClient` | Fetches all merchant page data concurrently | direct (in-process) |
| `couponsRouteHandler` | `uiComponents` | Passes fetched data as props for SSR rendering | direct (in-process) |
| `voucherCloudClient` | `redisClient_CouAstDem` | Reads cached VoucherCloud responses | direct (in-process) |
| `continuumCouponsAstroWebApp` | `voucherCloudRedisCache` | Reads cached merchant and offer data | Redis (ioredis) |

## Architecture Diagram References

- Component: `CouponsAstroWebAppComponents` (view key: `CouponsAstroWebAppComponents`)

> The relationship from `continuumCouponsAstroWebApp` to `voucherCloudRedisCache` is defined as a stub in `architecture/stubs.dsl` because the Redis cache target is not part of the federated model. See `architecture/models/relations.dsl` for the commented-out relationship.
