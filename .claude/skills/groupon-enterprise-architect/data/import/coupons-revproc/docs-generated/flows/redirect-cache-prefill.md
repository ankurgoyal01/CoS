---
service: "coupons-revproc"
title: "Redirect Cache Prefill"
generated: "2026-03-03"
type: flow
flow_name: "redirect-cache-prefill"
flow_type: scheduled
trigger: "Kubernetes cron job fires every 15 minutes (schedule: */15 * * * *)"
participants:
  - "continuumCouponsRevprocService"
  - "revproc_redirectCachePrefill"
  - "revproc_voucherCloudClient"
  - "revproc_redirectCacheService"
  - "continuumCouponsRevprocRedis"
architecture_ref: "dynamic-coupons-revproc-redirect-cache-prefill"
---

# Redirect Cache Prefill

## Summary

The Redirect Cache Prefill flow runs as a standalone Kubernetes cron job (`redirect-cache-prefill`) every 15 minutes. It fetches redirect URL mappings from the VoucherCloud API and writes them into Redis via the Redirect Cache Service. This ensures that redirect lookup data used by other components (such as the redirect sanitizer) remains fresh and available without requiring on-demand VoucherCloud API calls. The cron job uses the same Docker image as the main API service, launched with `JTIER_RUN_CMD=redirect-cache-prefill --`.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob resource (`jobSchedule: "*/15 * * * *"`)
- **Frequency**: Every 15 minutes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kubernetes CronJob | Schedules and launches the prefill container | Infrastructure |
| Redirect Cache Prefill Service (`revproc_redirectCachePrefill`) | Orchestrates the fetch from VoucherCloud and storage to cache | `revproc_redirectCachePrefill` |
| VoucherCloud API Client (`revproc_voucherCloudClient`) | Fetches redirect URL mappings from VoucherCloud | `revproc_voucherCloudClient` |
| VoucherCloud API | External source of redirect URL data | `voucherCloudApi` |
| Redirect Cache Service (`revproc_redirectCacheService`) | Writes redirect mappings into Redis | `revproc_redirectCacheService` |
| Redis | Stores the cached redirect mappings | `continuumCouponsRevprocRedis` |

## Steps

1. **Container starts**: Kubernetes CronJob launches the `redirect-cache-prefill` container. The `CouponsRedirectCachePrefillCommand` Dropwizard command is executed (selected by `JTIER_RUN_CMD`).
   - From: Kubernetes CronJob
   - To: `revproc_redirectCachePrefill`
   - Protocol: Container exec

2. **Fetch redirect mappings**: `RedirectCachePrefillService` calls `VoucherCloudApiClient.getWebsiteRedirects()` (or equivalent) via the `revproc_voucherCloudClient` to retrieve the current set of redirect URL mappings for the configured supported countries.
   - From: `revproc_redirectCachePrefill`
   - To: `voucherCloudApi`
   - Protocol: HTTPS (Retrofit2)

3. **Store redirects in cache**: `RedirectCachePrefillService` calls `RedirectCacheService.storeRedirects(redirectMappings)`, which uses the Jedis Redis client to write the mappings into Redis.
   - From: `revproc_redirectCachePrefill`
   - To: `revproc_redirectCacheService`
   - Protocol: Direct

4. **Write to Redis**: `RedirectCacheService` writes each redirect mapping to Redis via `revproc_redisClient`.
   - From: `revproc_redirectCacheService`
   - To: `continuumCouponsRevprocRedis`
   - Protocol: Redis (Jedis)

5. **Container exits**: On completion, the container writes to the termination signal file (`/tmp/signals/terminated`) and exits. Kubernetes marks the cron job as complete.
   - From: `revproc_redirectCachePrefill`
   - To: Kubernetes
   - Protocol: Container exit

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| VoucherCloud API unavailable | Exception logged; container exits with non-zero code | Redis cache not updated; existing cached values remain until next successful run (15 min) |
| Redis write failure | Exception logged | Partial cache update; stale data may persist |
| Container OOM or crash | Kubernetes marks job as failed; does not retry by default | Cache may be stale until next 15-minute window |

## Sequence Diagram

```
KubernetesCronJob -> RedirectCachePrefillContainer: exec (every 15 min)
RedirectCachePrefillContainer -> VoucherCloudAPI: GET /redirects HTTPS
VoucherCloudAPI --> RedirectCachePrefillContainer: List<WebsiteRedirect>
RedirectCachePrefillContainer -> RedirectCacheService: storeRedirects(mappings)
RedirectCacheService -> Redis: SET redirect mappings (Jedis)
Redis --> RedirectCacheService: OK
RedirectCachePrefillContainer -> Filesystem: touch /tmp/signals/terminated
KubernetesCronJob <-- RedirectCachePrefillContainer: exit 0
```

## Related

- Architecture dynamic view: `dynamic-coupons-revproc-redirect-cache-prefill`
- Related flows: [Coupon Feed Generation and Upload](coupon-feed-generation.md)
