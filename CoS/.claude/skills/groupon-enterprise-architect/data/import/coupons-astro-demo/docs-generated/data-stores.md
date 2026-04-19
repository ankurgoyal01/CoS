---
service: "coupons-astro-demo"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "voucherCloudRedisCache"
    type: "redis"
    purpose: "Read-only cache of VoucherCloud merchant, offer, advert, and meta data"
---

# Data Stores

## Overview

`coupons-astro-demo` does not own any data stores. It is a read-only consumer of a shared Redis cache (`voucherCloudRedisCache`) that is populated and managed externally by the VoucherCloud data pipeline. All cache reads are performed per-request during SSR, using `ioredis` through the `RedisClient` wrapper.

## Stores

### VoucherCloud Redis Cache (`voucherCloudRedisCache`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `voucherCloudRedisCache` (stub — external to federated model) |
| Purpose | Read-only source of merchant details, active offers, advertisements, similar merchants, top merchants, expired offers, and SEO meta content |
| Ownership | external (owned by VoucherCloud / data pipeline) |
| Migrations path | Not applicable — schema versioned via key suffixes (`:v3`, `:v4`) |

#### Key Entities

| Cache Key Pattern | Purpose | Key Fields |
|-------------------|---------|-----------|
| `vouchercloud:{COUNTRY}:{LOCALE}:groupon:getMerchantDetails:{permalink}:v4` | Merchant profile and branding data | `MerchantId`, `MerchantName`, `MerchantMedia`, `AverageVote`, `TotalVotes`, `Description`, `MerchantTier` |
| `vouchercloud:{COUNTRY}:{LOCALE}:groupon:VC_merchantOffers:{permalink}:v3` | Active offers for a merchant | `Offers[]` — `OfferId`, `OfferTitle`, `OfferType`, `OfferUrl`, `DiscountType`, `DiscountValue`, `ExpiryDateTime`, `IsPremiumOffer`, `OfferStatistics` |
| `vouchercloud:{COUNTRY}:{LOCALE}:groupon:getAdvertData:{type}:{limit}` | Advertisements for sidebar/carousel display | `Adverts[]` — `Id`, `AdvertName`, `AdvertType`, `MerchantSlug`, `Destination`, `Media[]`, `OfferTitle`, `OfferExpiry` |
| `vouchercloud:{COUNTRY}:{LOCALE}:groupon:getSimilarMerchants:{permalink}:{limit}:{country}` | Merchants similar to a given merchant | `Merchants[]` — `MerchantName`, `MerchantSlug`, `MerchantMedia`, `TotalOffers` |
| `vouchercloud:{COUNTRY}:{LOCALE}:groupon:getTopMerchants:{brandType}:{categoryId}:{limit}:{country}` | Top-ranked merchants by offer count | `Merchants[]` — `MerchantName`, `MerchantSlug`, `MerchantMedia`, `OfferCount` |
| `vouchercloud:{COUNTRY}:{LOCALE}:groupon:VC_merchantExpiredOffers:{permalink}:v3` | Expired offers that may still be valid | `Offers[]` — `OfferId`, `OfferTitle`, `MerchantId`, `Code`, `IsUnique` |
| `vouchercloud:{COUNTRY}:{LOCALE}:groupon:VC_merchantMetaContent:{permalink}:v3` | SEO and editorial content for merchant pages | `SerpsDetails` (Title, Description), `RobotsNoIndex`, `WebsiteRichContent`, `WebsiteFaqs[]`, `DidYouKnow`, `VouchercloudPicks` |

#### Access Patterns

- **Read**: All access is read-only. The `RedisClient.get()` method prefixes the key with `vouchercloud:{COUNTRY}:{LOCALE}:groupon`, calls `ioredis.get()`, then parses the JSON envelope and returns the value at the `d` key.
- **Write**: No write operations are performed by this service at runtime. The `RedisClient.set()` and `rawSet()` methods exist in the wrapper but are not called by any route handler or middleware.
- **Indexes**: Not applicable — direct key lookups only.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `voucherCloudRedisCache` | Redis (Google Cloud Memorystore in staging: `coupon-worker-memorystore.us-central1.caches.stable.gcp.groupondev.com`) | Serves all merchant, offer, and advert data for SSR page rendering | Not configured by this service — TTL managed by VoucherCloud pipeline |

## Data Flows

All data originates in VoucherCloud's backend and is written to Redis by an external pipeline (not part of this repository). `coupons-astro-demo` reads from this cache on every page request. There are no ETL processes, CDC streams, replication, or materialized views within this service.
