---
service: "coupons-itier-global"
title: "Coupon Browse"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "coupon-browse"
flow_type: synchronous
trigger: "HTTP GET /coupons or /category/{category}"
participants:
  - "itierServer"
  - "couponsItierGlobal_cacheClient"
  - "continuumCouponsRedisCache"
  - "couponsItierGlobal_vouchercloudClient"
  - "couponsItierGlobal_gapiClient"
architecture_ref: "dynamic-coupon-browse"
---

# Coupon Browse

## Summary

When a consumer navigates to the coupons landing page (`/coupons`) or a category listing page (`/category/{category}`), the I-Tier server orchestrates data retrieval from multiple sources, assembles a complete render payload, and returns a server-side rendered HTML page. Coupon and category data is sourced from Vouchercloud API; deal and redemption data is sourced from GAPI (GraphQL). Both data sets are cached in Redis to minimise upstream latency and are served from cache on repeat requests.

## Trigger

- **Type**: user-action
- **Source**: Consumer browser navigating to `/coupons` or `/category/{category}` (optionally served via Akamai CDN edge cache on cache hit)
- **Frequency**: Per-request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| I-Tier Server | Receives request, orchestrates data fetching, executes SSR, returns HTML page | `itierServer` |
| Cache Client | Checks and populates Redis for coupon data and render payloads | `couponsItierGlobal_cacheClient` |
| Coupons I-Tier Redis Cache | Stores coupon offer data, category listings, and render payloads | `continuumCouponsRedisCache` |
| Vouchercloud Client | Fetches coupon, merchant, and category data from Vouchercloud API | `couponsItierGlobal_vouchercloudClient` |
| GAPI Client | Fetches deal and redemption data from GAPI (GraphQL) | `couponsItierGlobal_gapiClient` |

## Steps

1. **Receives page request**: Consumer browser (or Akamai edge on cache miss) sends `GET /coupons` or `GET /category/{category}` to the I-Tier server.
   - From: `Browser / Akamai CDN`
   - To: `itierServer`
   - Protocol: REST/HTTPS

2. **Checks render payload cache**: I-Tier server queries Cache Client to check whether a cached render payload exists for this route and locale.
   - From: `itierServer`
   - To: `couponsItierGlobal_cacheClient`
   - Protocol: Internal

3. **Reads from Redis**: Cache Client queries `continuumCouponsRedisCache` for a cached payload.
   - From: `couponsItierGlobal_cacheClient`
   - To: `continuumCouponsRedisCache`
   - Protocol: Redis

4. **Cache hit — returns cached payload**: If a fresh render payload is found, it is returned to `itierServer`, which renders and returns the HTML page. Flow ends here on full cache hit.
   - From: `continuumCouponsRedisCache`
   - To: `couponsItierGlobal_cacheClient` → `itierServer`
   - Protocol: Redis / Internal

5. **Cache miss — fetches coupon data from Vouchercloud**: On cache miss, `itierServer` requests coupon and category data via `couponsItierGlobal_vouchercloudClient`.
   - From: `itierServer`
   - To: `couponsItierGlobal_vouchercloudClient`
   - Protocol: Internal

6. **Calls Vouchercloud API**: Vouchercloud Client fetches offers, merchants, and category listings for the requested page.
   - From: `couponsItierGlobal_vouchercloudClient`
   - To: `vouchercloudApi_5b7d2e`
   - Protocol: REST/HTTPS

7. **Fetches deal data from GAPI**: In parallel (or sequentially), `itierServer` requests deal and redemption data via `couponsItierGlobal_gapiClient`.
   - From: `itierServer`
   - To: `couponsItierGlobal_gapiClient`
   - Protocol: Internal

8. **Executes GraphQL query**: GAPI Client sends a GraphQL query to GAPI for the relevant deals.
   - From: `couponsItierGlobal_gapiClient`
   - To: `gapi_1f2a9c`
   - Protocol: GraphQL/HTTPS

9. **Caches assembled data**: Cache Client writes the fetched coupon and deal data (and optionally the assembled render payload) into Redis.
   - From: `couponsItierGlobal_cacheClient`
   - To: `continuumCouponsRedisCache`
   - Protocol: Redis

10. **Renders and returns page**: `itierServer` assembles the data using Preact SSR and returns the rendered HTML page to the consumer browser.
    - From: `itierServer`
    - To: `Browser`
    - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable | All data fetched live from upstream APIs | Page rendered correctly; higher latency |
| Vouchercloud API unavailable | No documented fallback | Coupon sections may be empty or page may error |
| GAPI unavailable | No documented fallback | Deal sections may be omitted or page may error |
| Partial data from either API | No documented partial-failure strategy | Page may render with incomplete content sections |

## Sequence Diagram

```
Browser -> itierServer: GET /coupons or /category/{category}
itierServer -> couponsItierGlobal_cacheClient: getPayload(routeKey, locale)
couponsItierGlobal_cacheClient -> continuumCouponsRedisCache: GET payload:{route}:{locale}
continuumCouponsRedisCache --> couponsItierGlobal_cacheClient: HIT: render payload
couponsItierGlobal_cacheClient --> itierServer: render payload
itierServer --> Browser: HTTP 200 SSR HTML page

alt Cache Miss
  continuumCouponsRedisCache --> couponsItierGlobal_cacheClient: MISS
  itierServer -> couponsItierGlobal_vouchercloudClient: fetchCoupons(category, locale)
  couponsItierGlobal_vouchercloudClient -> vouchercloudApi_5b7d2e: GET /coupons?category=...
  vouchercloudApi_5b7d2e --> couponsItierGlobal_vouchercloudClient: coupon data
  itierServer -> couponsItierGlobal_gapiClient: queryDeals(category, locale)
  couponsItierGlobal_gapiClient -> gapi_1f2a9c: GraphQL query
  gapi_1f2a9c --> couponsItierGlobal_gapiClient: deal data
  itierServer -> couponsItierGlobal_cacheClient: setPayload(routeKey, locale, data)
  couponsItierGlobal_cacheClient -> continuumCouponsRedisCache: SET payload:{route}:{locale}
  itierServer --> Browser: HTTP 200 SSR HTML page
end
```

## Related

- Architecture dynamic view: `dynamic-coupon-browse` (not yet defined in `views/dynamics.dsl`)
- Related flows: [Merchant Redirect](merchant-redirect.md), [Offer Redemption](offer-redemption.md), [Redirect Cache Refresh](redirect-cache-refresh.md)
