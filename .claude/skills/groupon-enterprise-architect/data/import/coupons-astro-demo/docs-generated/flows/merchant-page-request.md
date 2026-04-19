---
service: "coupons-astro-demo"
title: "Merchant Page Request"
generated: "2026-03-03"
type: flow
flow_name: "merchant-page-request"
flow_type: synchronous
trigger: "HTTP GET /coupons/[merchantPermalink]"
participants:
  - "Browser / Crawler"
  - "dependenciesMiddleware"
  - "couponsRouteHandler"
  - "voucherCloudClient"
  - "redisClient_CouAstDem"
  - "voucherCloudRedisCache"
  - "uiComponents"
architecture_ref: "CouponsAstroWebAppComponents"
---

# Merchant Page Request

## Summary

This is the primary user-facing flow: a browser or search-engine crawler requests a merchant coupon page by permalink (e.g., `GET /coupons/amazon`). The Astro SSR runtime runs the dependencies middleware to initialize clients, then the route handler concurrently fetches seven categories of data from the Redis cache via the VoucherCloud client, assembles prop data, renders Svelte and Astro UI components server-side, and returns a complete HTML page to the caller.

## Trigger

- **Type**: api-call (HTTP request)
- **Source**: Browser or search-engine crawler
- **Frequency**: On-demand, per page view

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser / Crawler | Initiates HTTP GET request; receives rendered HTML | External |
| Dependencies Middleware | Intercepts every request; initializes Redis and VoucherCloud clients | `dependenciesMiddleware` |
| Merchant Coupons Route Handler | Orchestrates all data fetches and page rendering | `couponsRouteHandler` |
| VoucherCloud Client | Translates data requests into typed Redis reads | `voucherCloudClient` |
| Redis Client | Executes prefixed Redis GET operations and unwraps JSON envelope | `redisClient_CouAstDem` |
| VoucherCloud Redis Cache | External Redis store containing all merchant and offer data | `voucherCloudRedisCache` |
| UI Components | Renders the assembled data into HTML (Svelte + Astro) | `uiComponents` |

## Steps

1. **Receive HTTP request**: Browser issues `GET /coupons/amazon` (where `amazon` is the merchant permalink).
   - From: `Browser / Crawler`
   - To: `continuumCouponsAstroWebApp` (Node.js standalone server on port 4321)
   - Protocol: HTTP

2. **Run dependencies middleware**: `dependenciesMiddleware` initializes an `ioredis` connection (lazy connect) with the configured `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`, and `REDIS_DB` values. Wraps it in `RedisClient` with country/locale prefix derived from `COUNTRY_CODE` / `LOCALE_CODE`. Creates `VoucherCloudClient` wrapping the Redis client. Injects both into `context.locals`.
   - From: `dependenciesMiddleware`
   - To: `redisClient_CouAstDem`, `voucherCloudClient`
   - Protocol: direct (in-process)

3. **Fetch merchant details**: Route handler calls `voucherCloudClient.getMerchantDetails('amazon')`. Client reads Redis key `vouchercloud:US:en_US:groupon:getMerchantDetails:amazon:v4`, parses the `d` envelope, validates `VC_merchantDetails.Details` array, and returns `Details[0]` as a `MerchantDetail`.
   - From: `couponsRouteHandler`
   - To: `voucherCloudRedisCache` (via `voucherCloudClient` -> `redisClient_CouAstDem`)
   - Protocol: Redis

4. **Guard: missing merchant**: If `getMerchantDetails` returns `null`, the route handler calls `Astro.redirect('/404')` and terminates the flow.
   - From: `couponsRouteHandler`
   - To: `Browser / Crawler`
   - Protocol: HTTP 302

5. **Concurrent data fetch**: Route handler calls `Promise.all([...])` to fetch six additional data sets in parallel:
   - `getMerchantOffers(permalink)` — key `VC_merchantOffers:{permalink}:v3`
   - `getAdverts('Carousel', 32)` — key `getAdvertData:32768:32`
   - `getSimilarMerchants(permalink, 12, 'US')` — key `getSimilarMerchants:{permalink}:12:US`
   - `getTopMerchants('Merchant', '', 20, 'US')` — key `getTopMerchants:Merchant::20:US`
   - `getExpiredOffers(permalink)` — key `VC_merchantExpiredOffers:{permalink}:v3`
   - `getMerchantMetaContent(permalink)` — key `VC_merchantMetaContent:{permalink}:v3`
   - From: `couponsRouteHandler` -> `voucherCloudClient`
   - To: `voucherCloudRedisCache`
   - Protocol: Redis (6 concurrent GET operations)

6. **Assemble page data**: Route handler coalesces null returns to empty arrays, computes offer type statistics (`offerTypeStats`), and extracts the merchant logo `Media` item (where `MediaType === 'Logo'`).
   - From: `couponsRouteHandler`
   - To: `uiComponents` (prop construction)
   - Protocol: direct (in-process)

7. **Render HTML**: Astro SSR renders the `Layout` template wrapping a `SidebarLayout` with all assembled data passed as component props. Svelte components (`OffersList`, `AdvertCarousel`, `SidebarListMerchants`, `StarRating`, etc.) are rendered server-side to static HTML. Meta tags (title, description) are set from `MerchantMetaContent.SerpsDetails` if available.
   - From: `uiComponents`
   - To: `Browser / Crawler`
   - Protocol: HTTP (full HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Merchant not found in Redis (null) | `Astro.redirect('/404')` | HTTP 302 redirect to /404 |
| Redis connection failure | `ioredis` logs error; command times out after 5s (up to 3 retries) | Merchant lookup returns null → redirect to /404 |
| Offers/adverts/similar merchants return null | Nullish coalescing to empty array (`?? []`) | Page renders with empty sections; no crash |
| Meta content returns null | Fallback to `${merchant.MerchantName} Coupons` as page title | Page renders with default title/description |
| Redis JSON parse failure | `RedisClient.get()` catches parse error, returns null | Same as cache miss; graceful degradation |

## Sequence Diagram

```
Browser         dependenciesMiddleware    couponsRouteHandler    voucherCloudClient    Redis
  |                     |                        |                      |               |
  |--GET /coupons/amazon->|                       |                      |               |
  |                     |--init RedisClient------->|                      |               |
  |                     |--init VoucherCloudClient->|                     |               |
  |                     |--inject context.locals--->|                      |               |
  |                     |                        |--getMerchantDetails()--->|               |
  |                     |                        |                      |--GET key:v4---->|
  |                     |                        |                      |<--JSON blob-----|
  |                     |                        |<--MerchantDetail-----|               |
  |                     |                        |                      |               |
  |                     |              [if null] |--Astro.redirect('/404')------------->|
  |                     |                        |                      |               |
  |                     |                        |--Promise.all([6 fetches])----------->|
  |                     |                        |                      |<--6x responses-|
  |                     |                        |<--[offers,adverts,similar,top,expired,meta]
  |                     |                        |                      |               |
  |                     |                        |--render Svelte/Astro components      |
  |<---HTML response----|                        |                      |               |
```

## Related

- Architecture dynamic view: `CouponsAstroWebAppComponents`
- Related flows: [Dependency Initialization](dependency-initialization.md), [Redis Cache Read](redis-cache-read.md), [Offer Filter](offer-filter.md)
