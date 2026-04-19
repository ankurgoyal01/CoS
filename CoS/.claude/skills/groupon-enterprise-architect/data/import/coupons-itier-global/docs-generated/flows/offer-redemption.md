---
service: "coupons-itier-global"
title: "Offer Redemption"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "offer-redemption"
flow_type: synchronous
trigger: "HTTP GET /redirect/offers/{id}"
participants:
  - "itierServer"
  - "couponsItierGlobal_cacheClient"
  - "continuumCouponsRedisCache"
  - "couponsItierGlobal_vouchercloudClient"
architecture_ref: "dynamic-offer-redemption"
---

# Offer Redemption

## Summary

When a consumer clicks to redeem a coupon offer, the browser sends `GET /redirect/offers/{id}` to the I-Tier server. The service resolves the destination affiliate URL for the specific offer by checking Redis first and falling back to Vouchercloud API on a cache miss. Once the URL is resolved, the service issues an HTTP 302 redirect, sending the consumer directly to the offer's redemption destination.

## Trigger

- **Type**: user-action
- **Source**: Consumer clicking a "Redeem" or "Get Coupon" link on a coupons page, which calls `GET /redirect/offers/{id}`
- **Frequency**: Per-request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| I-Tier Server | Receives the HTTP request, orchestrates resolution, issues redirect response | `itierServer` |
| Cache Client | Looks up and caches offer redirect URLs in Redis | `couponsItierGlobal_cacheClient` |
| Coupons I-Tier Redis Cache | Stores offer redirect URL mappings | `continuumCouponsRedisCache` |
| Vouchercloud Client | Fetches offer redirect URL from Vouchercloud API on cache miss | `couponsItierGlobal_vouchercloudClient` |

## Steps

1. **Receives redemption request**: Consumer browser sends `GET /redirect/offers/{id}` to the I-Tier server (optionally via Akamai CDN edge).
   - From: `Browser / Akamai CDN`
   - To: `itierServer`
   - Protocol: REST/HTTPS

2. **Requests redirect URL from cache**: I-Tier server instructs Cache Client to look up the offer redirect URL.
   - From: `itierServer`
   - To: `couponsItierGlobal_cacheClient`
   - Protocol: Internal

3. **Queries Redis for offer redirect**: Cache Client queries the Redis cache for the offer's stored redirect URL.
   - From: `couponsItierGlobal_cacheClient`
   - To: `continuumCouponsRedisCache`
   - Protocol: Redis

4. **Cache hit — returns offer URL**: If found in Redis, the URL is returned. I-Tier server immediately issues HTTP 302. Flow ends here on cache hit.
   - From: `continuumCouponsRedisCache`
   - To: `couponsItierGlobal_cacheClient` → `itierServer`
   - Protocol: Redis / Internal

5. **Cache miss — delegates to Vouchercloud Client**: Cache Client forwards the lookup to Vouchercloud Client.
   - From: `couponsItierGlobal_cacheClient`
   - To: `couponsItierGlobal_vouchercloudClient`
   - Protocol: Internal

6. **Fetches offer redirect from Vouchercloud**: Vouchercloud Client calls Vouchercloud API to retrieve the offer's affiliate redirect URL.
   - From: `couponsItierGlobal_vouchercloudClient`
   - To: `vouchercloudApi_5b7d2e`
   - Protocol: REST/HTTPS

7. **Writes offer redirect to Redis**: Cache Client stores the fetched offer URL in Redis for future requests.
   - From: `couponsItierGlobal_cacheClient`
   - To: `continuumCouponsRedisCache`
   - Protocol: Redis

8. **Issues HTTP 302 redirect**: I-Tier server returns an HTTP 302 response directing the consumer's browser to the resolved offer affiliate destination.
   - From: `itierServer`
   - To: `Browser`
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable | Cache Client bypasses Redis and calls Vouchercloud API directly | Offer redirect resolved live; increased latency and upstream load |
| Vouchercloud API unavailable on cache miss | No documented fallback | HTTP error response returned to consumer |
| Unknown or expired offer ID | Vouchercloud returns no matching redirect rule | HTTP 404 or redirect to fallback destination (not specified in architecture model) |

## Sequence Diagram

```
Browser -> itierServer: GET /redirect/offers/{id}
itierServer -> couponsItierGlobal_cacheClient: lookup(offerId)
couponsItierGlobal_cacheClient -> continuumCouponsRedisCache: GET redirect:offer:{id}
continuumCouponsRedisCache --> couponsItierGlobal_cacheClient: HIT: offer URL
couponsItierGlobal_cacheClient --> itierServer: offer URL
itierServer --> Browser: HTTP 302 -> offer affiliate destination

alt Cache Miss
  continuumCouponsRedisCache --> couponsItierGlobal_cacheClient: MISS
  couponsItierGlobal_cacheClient -> couponsItierGlobal_vouchercloudClient: fetchOfferRedirect(id)
  couponsItierGlobal_vouchercloudClient -> vouchercloudApi_5b7d2e: GET /offers/{id}/redirect
  vouchercloudApi_5b7d2e --> couponsItierGlobal_vouchercloudClient: offer URL
  couponsItierGlobal_vouchercloudClient --> couponsItierGlobal_cacheClient: offer URL
  couponsItierGlobal_cacheClient -> continuumCouponsRedisCache: SET redirect:offer:{id}
  couponsItierGlobal_cacheClient --> itierServer: offer URL
  itierServer --> Browser: HTTP 302 -> offer affiliate destination
end
```

## Related

- Architecture dynamic view: `dynamic-offer-redemption` (not yet defined in `views/dynamics.dsl`)
- Related flows: [Merchant Redirect](merchant-redirect.md), [Redirect Cache Refresh](redirect-cache-refresh.md)
