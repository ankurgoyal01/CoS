---
service: "coupons-itier-global"
title: "Merchant Redirect"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "merchant-redirect"
flow_type: synchronous
trigger: "HTTP GET /redirect/merchant/{id}"
participants:
  - "itierServer"
  - "couponsItierGlobal_cacheClient"
  - "continuumCouponsRedisCache"
  - "couponsItierGlobal_vouchercloudClient"
architecture_ref: "dynamic-merchant-redirect"
---

# Merchant Redirect

## Summary

When a consumer or affiliate system requests `/redirect/merchant/{id}`, the service resolves the destination affiliate URL for the given merchant and issues an HTTP 302 redirect. Redirect rules are served from the Redis cache where possible; on a cache miss, the rule is fetched live from Vouchercloud API and stored in Redis for subsequent requests.

## Trigger

- **Type**: api-call
- **Source**: Consumer browser or affiliate tracking system sending GET `/redirect/merchant/{id}`
- **Frequency**: Per-request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| I-Tier Server | Receives the HTTP request, orchestrates resolution, issues redirect response | `itierServer` |
| Cache Client | Checks Redis for a cached redirect rule; stores the rule on cache miss | `couponsItierGlobal_cacheClient` |
| Coupons I-Tier Redis Cache | Stores merchant redirect URL mappings | `continuumCouponsRedisCache` |
| Vouchercloud Client | Fetches merchant redirect rule from Vouchercloud API on cache miss | `couponsItierGlobal_vouchercloudClient` |

## Steps

1. **Receives redirect request**: Browser or affiliate system sends `GET /redirect/merchant/{id}` to the I-Tier server.
   - From: `Browser / Akamai CDN`
   - To: `itierServer`
   - Protocol: REST/HTTPS

2. **Checks redirect cache**: I-Tier server delegates to Cache Client to look up the merchant redirect rule by ID.
   - From: `itierServer`
   - To: `couponsItierGlobal_cacheClient`
   - Protocol: Internal

3. **Reads cached rule**: Cache Client queries Redis for the merchant's redirect URL.
   - From: `couponsItierGlobal_cacheClient`
   - To: `continuumCouponsRedisCache`
   - Protocol: Redis

4. **Cache hit — returns redirect URL**: If the rule is found in Redis, the URL is returned up the call chain and the I-Tier server issues an HTTP 302 to the merchant affiliate URL. Flow ends here on cache hit.
   - From: `continuumCouponsRedisCache`
   - To: `couponsItierGlobal_cacheClient` → `itierServer`
   - Protocol: Redis / Internal

5. **Cache miss — fetches from Vouchercloud**: If no cached rule exists, Cache Client delegates to Vouchercloud Client to fetch the merchant redirect rule live.
   - From: `couponsItierGlobal_cacheClient`
   - To: `couponsItierGlobal_vouchercloudClient`
   - Protocol: Internal

6. **Requests merchant redirect rule**: Vouchercloud Client calls the Vouchercloud API for the merchant's affiliate URL.
   - From: `couponsItierGlobal_vouchercloudClient`
   - To: `vouchercloudApi_5b7d2e`
   - Protocol: REST/HTTPS

7. **Stores rule in Redis**: Cache Client writes the fetched redirect rule into Redis for future requests.
   - From: `couponsItierGlobal_cacheClient`
   - To: `continuumCouponsRedisCache`
   - Protocol: Redis

8. **Issues HTTP redirect**: I-Tier server returns an HTTP 302 response directing the client to the resolved merchant affiliate URL.
   - From: `itierServer`
   - To: `Browser / Akamai CDN`
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable | Cache Client falls through to Vouchercloud API | Redirect resolved live; higher latency |
| Vouchercloud API unavailable | No fallback documented in architecture model | HTTP error or redirect failure returned to client |
| Unknown merchant ID | Vouchercloud returns no rule | HTTP 404 or redirect to a fallback URL (not specified in architecture model) |

## Sequence Diagram

```
Browser -> itierServer: GET /redirect/merchant/{id}
itierServer -> couponsItierGlobal_cacheClient: lookup(merchantId)
couponsItierGlobal_cacheClient -> continuumCouponsRedisCache: GET redirect:merchant:{id}
continuumCouponsRedisCache --> couponsItierGlobal_cacheClient: HIT: redirect URL
couponsItierGlobal_cacheClient --> itierServer: redirect URL
itierServer --> Browser: HTTP 302 -> merchant affiliate URL

alt Cache Miss
  continuumCouponsRedisCache --> couponsItierGlobal_cacheClient: MISS
  couponsItierGlobal_cacheClient -> couponsItierGlobal_vouchercloudClient: fetchMerchantRedirect(id)
  couponsItierGlobal_vouchercloudClient -> vouchercloudApi_5b7d2e: GET /merchant/{id}/redirect
  vouchercloudApi_5b7d2e --> couponsItierGlobal_vouchercloudClient: redirect URL
  couponsItierGlobal_vouchercloudClient --> couponsItierGlobal_cacheClient: redirect URL
  couponsItierGlobal_cacheClient -> continuumCouponsRedisCache: SET redirect:merchant:{id}
  couponsItierGlobal_cacheClient --> itierServer: redirect URL
  itierServer --> Browser: HTTP 302 -> merchant affiliate URL
end
```

## Related

- Architecture dynamic view: `dynamic-merchant-redirect` (not yet defined in `views/dynamics.dsl`)
- Related flows: [Offer Redemption](offer-redemption.md), [Redirect Cache Refresh](redirect-cache-refresh.md)
