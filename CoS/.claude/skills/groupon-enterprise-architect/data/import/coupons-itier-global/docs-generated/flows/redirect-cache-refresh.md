---
service: "coupons-itier-global"
title: "Redirect Cache Refresh"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "redirect-cache-refresh"
flow_type: scheduled
trigger: "node-schedule cron job within redirectCacheCron component"
participants:
  - "redirectCacheCron"
  - "couponsItierGlobal_vouchercloudClient"
  - "couponsItierGlobal_cacheClient"
  - "continuumCouponsRedisCache"
architecture_ref: "dynamic-redirect-cache-refresh"
---

# Redirect Cache Refresh

## Summary

`redirectCacheCron` is a scheduled background job running inside the `continuumCouponsItierGlobalService` process. It periodically fetches all current merchant and offer redirect rules from Vouchercloud API and writes them into `continuumCouponsRedisCache`. This proactive cache warming ensures that redirect requests are served from cache rather than requiring live upstream lookups, keeping redirect latency low and reducing load on the Vouchercloud API.

## Trigger

- **Type**: schedule
- **Source**: `node-schedule` cron expression configured within the `redirectCacheCron` component
- **Frequency**: Periodic (exact schedule interval not specified in architecture model)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Redirect Cache Cron | Initiates the scheduled refresh; orchestrates the fetch-and-store cycle | `redirectCacheCron` |
| Vouchercloud Client | Fetches all current redirect rules from Vouchercloud API | `couponsItierGlobal_vouchercloudClient` |
| Cache Client | Writes fetched redirect rules into Redis | `couponsItierGlobal_cacheClient` |
| Coupons I-Tier Redis Cache | Stores the refreshed redirect rule set | `continuumCouponsRedisCache` |

## Steps

1. **Cron fires**: `node-schedule` triggers `redirectCacheCron` at the configured interval.
   - From: `node-schedule` (internal scheduler)
   - To: `redirectCacheCron`
   - Protocol: Internal / scheduled

2. **Requests redirect rules from Vouchercloud**: `redirectCacheCron` delegates to `couponsItierGlobal_vouchercloudClient` to fetch the full set of current redirect rules.
   - From: `redirectCacheCron`
   - To: `couponsItierGlobal_vouchercloudClient`
   - Protocol: Internal

3. **Fetches redirect rules from Vouchercloud API**: Vouchercloud Client calls the Vouchercloud API to retrieve all merchant and offer redirect rule mappings.
   - From: `couponsItierGlobal_vouchercloudClient`
   - To: `vouchercloudApi_5b7d2e`
   - Protocol: REST/HTTPS

4. **Returns redirect rules**: Vouchercloud API responds with the current full set of redirect rules.
   - From: `vouchercloudApi_5b7d2e`
   - To: `couponsItierGlobal_vouchercloudClient` → `redirectCacheCron`
   - Protocol: REST/HTTPS / Internal

5. **Stores redirect rules in Redis**: `redirectCacheCron` passes the rules to `couponsItierGlobal_cacheClient`, which writes each rule into `continuumCouponsRedisCache`.
   - From: `redirectCacheCron`
   - To: `couponsItierGlobal_cacheClient`
   - Protocol: Internal

6. **Writes to Redis cache**: Cache Client writes all redirect rule entries into Redis.
   - From: `couponsItierGlobal_cacheClient`
   - To: `continuumCouponsRedisCache`
   - Protocol: Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Vouchercloud API unavailable during cron run | No documented retry strategy in architecture model | Redis redirect rules remain stale until the next successful cron execution |
| Redis write failure | No documented retry strategy in architecture model | Redirect rules not refreshed; serving stale cached rules or falling back to live lookups on miss |
| Partial API response | No documented handling | Partial rule set written; some redirects may resolve stale until next refresh |

## Sequence Diagram

```
node-schedule -> redirectCacheCron: trigger (cron interval)
redirectCacheCron -> couponsItierGlobal_vouchercloudClient: fetchAllRedirectRules()
couponsItierGlobal_vouchercloudClient -> vouchercloudApi_5b7d2e: GET /redirect-rules
vouchercloudApi_5b7d2e --> couponsItierGlobal_vouchercloudClient: redirect rules payload
couponsItierGlobal_vouchercloudClient --> redirectCacheCron: redirect rules
redirectCacheCron -> couponsItierGlobal_cacheClient: store(redirectRules)
couponsItierGlobal_cacheClient -> continuumCouponsRedisCache: SET redirect:merchant:{id}, redirect:offer:{id} ...
continuumCouponsRedisCache --> couponsItierGlobal_cacheClient: OK
```

## Related

- Architecture dynamic view: `dynamic-redirect-cache-refresh` (not yet defined in `views/dynamics.dsl`)
- Related flows: [Merchant Redirect](merchant-redirect.md), [Offer Redemption](offer-redemption.md)
