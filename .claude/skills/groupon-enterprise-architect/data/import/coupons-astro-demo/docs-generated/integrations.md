---
service: "coupons-astro-demo"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

`coupons-astro-demo` has a single runtime integration: a read-only connection to the VoucherCloud Redis cache. All merchant, offer, advert, and meta data is sourced from this cache. There are no internal Groupon service-to-service calls, no REST or gRPC integrations, and no third-party API calls at runtime.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| VoucherCloud Redis Cache | Redis (ioredis) | Source of all merchant, offer, advert, similar/top merchant, expired offer, and SEO meta data | yes | `voucherCloudRedisCache` |

### VoucherCloud Redis Cache Detail

- **Protocol**: Redis — binary-compatible TCP protocol via `ioredis` client
- **Base URL / SDK**: `ioredis` ^5.7.0; host configured via `REDIS_HOST` env var. Staging host: `coupon-worker-memorystore.us-central1.caches.stable.gcp.groupondev.com`
- **Auth**: Optional password via `REDIS_PASSWORD` env var; database index via `REDIS_DB` env var (default: `0`)
- **Purpose**: Provides pre-computed, VoucherCloud-sourced data blobs for merchant pages, avoiding direct VoucherCloud API calls on each request and enabling fast SSR
- **Failure mode**: If Redis is unreachable or a cache key is missing, the `VoucherCloudClient` methods return `null`. The merchant coupons route handler redirects to `/404` on a null merchant result; other null results (offers, adverts, etc.) degrade gracefully to empty arrays
- **Circuit breaker**: No circuit breaker configured. Redis connection retries up to 3 times per request (`maxRetriesPerRequest: 3`) with a 10-second connect timeout and 5-second command timeout. Redis errors are logged to `console.error` but do not crash the process.

## Internal Dependencies

> No evidence found in codebase. No internal Groupon service calls are made at runtime.

## Consumed By

> Upstream consumers are tracked in the central architecture model. This service serves end-user browsers and search engine crawlers via HTTP.

## Dependency Health

The `dependenciesMiddleware` initializes an `ioredis` connection on every incoming request using `lazyConnect: true`, meaning the TCP connection is not established until the first Redis command. Connection errors emit an `error` event logged to `console.error` with the message `"Redis connection error:"`. Successful connections log `"Redis connected successfully"`. The connection is kept alive across the response lifecycle (not closed per-request, per the inline comment in `src/middleware.ts`).
