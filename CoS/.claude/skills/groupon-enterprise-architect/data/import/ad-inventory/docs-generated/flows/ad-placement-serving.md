---
service: "ad-inventory"
title: "Ad Placement Serving"
generated: "2026-03-03"
type: flow
flow_name: "ad-placement-serving"
flow_type: synchronous
trigger: "Inbound HTTP GET to /ai/api/v1/placement from Groupon frontend page or app"
participants:
  - "continuumAdInventoryService_adInventoryPlacementResource"
  - "continuumAdInventoryService_audienceApi"
  - "continuumAdInventoryRedis"
  - "continuumAdInventoryService_smaMetricsLogger"
  - "continuumSmaMetrics"
architecture_ref: "components-continuum-ad-inventory-service-components"
---

# Ad Placement Serving

## Summary

When a Groupon frontend page or app requires an ad slot, it issues an HTTP GET to `/ai/api/v1/placement` with page, platform, locale, placements, country, division, app, and optional cookie parameters. The service resolves which audiences the requesting user belongs to (via in-memory and Redis cache lookups using `c_cookie` and `b_cookie`), selects the appropriate ad content, emits placement metrics to SMA, and returns the ad content. This is the primary real-time, latency-sensitive path of the service.

## Trigger

- **Type**: api-call
- **Source**: Groupon frontend pages and mobile apps
- **Frequency**: Per-request (high volume, continuous)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Groupon Frontend | Initiates ad slot request | External caller |
| Ad Inventory Placement Resource | Receives request, orchestrates audience resolution, returns ad content | `continuumAdInventoryService_adInventoryPlacementResource` |
| Audience API | Resolves eligible audience targets from in-memory and Redis caches | `continuumAdInventoryService_audienceApi` |
| Ad Inventory Redis | Stores audience bloom filter bytes and audience target lists for fast lookup | `continuumAdInventoryRedis` |
| SMA Metrics Logger | Emits placement request counters | `continuumAdInventoryService_smaMetricsLogger` |
| SMA Metrics | Receives and aggregates metrics | `continuumSmaMetrics` |

## Steps

1. **Receive placement request**: Frontend issues `GET /ai/api/v1/placement?page=<page>&platform=<platform>&locale=<locale>&placements=<ids>&country=<country>&division=<div>&app=<app>&c_cookie=<cc>&b_cookie=<bc>`.
   - From: Groupon Frontend
   - To: `continuumAdInventoryService_adInventoryPlacementResource`
   - Protocol: REST / HTTP

2. **Build placement request model**: `AdInventoryPlacementResource` parses query parameters into an `AdPlacementRequest` object, including cookie values for audience membership checks.
   - From: `continuumAdInventoryService_adInventoryPlacementResource`
   - To: internal (in-process)
   - Protocol: direct

3. **Resolve eligible audiences**: `AdInventoryPlacementResource` calls `AudienceApi.getTargetedAudiences(request, adFormat)` to determine which audience-targeted ad content the user is eligible for.
   - From: `continuumAdInventoryService_adInventoryPlacementResource`
   - To: `continuumAdInventoryService_audienceApi`
   - Protocol: in-memory call

4. **Look up audience target cache**: `AudienceApi` constructs a cache key from `(placementId, country, adFormat)` and queries `audienceTargetCache` (Guava in-memory cache backed by Redis) for the list of configured audience targets.
   - From: `continuumAdInventoryService_audienceApi`
   - To: `continuumAdInventoryRedis`
   - Protocol: Redis (Redisson)

5. **Check audience membership**: For each audience target returned, `AudienceApi` checks `audienceCache` for the `Audience` object keyed by `(audienceId, audienceSegment)` and calls `aud.isMember(bCookie, cCookie)` — a bloom filter membership test using the user's cookies.
   - From: `continuumAdInventoryService_audienceApi`
   - To: `continuumAdInventoryRedis`
   - Protocol: Redis (Redisson)

6. **Collect eligible audiences**: `AudienceApi` returns the list of `AudienceTargetContent` objects where the user passed the bloom filter membership test.
   - From: `continuumAdInventoryService_audienceApi`
   - To: `continuumAdInventoryService_adInventoryPlacementResource`
   - Protocol: in-process return

7. **Emit placement metrics**: `AdInventoryPlacementResource` calls `SMAMetricsLogger` to emit placement counter metrics.
   - From: `continuumAdInventoryService_adInventoryPlacementResource`
   - To: `continuumAdInventoryService_smaMetricsLogger`
   - Protocol: Metrics SDK

8. **Submit metrics to SMA**: `SMAMetricsLogger` submits the counter to Groupon's SMA metrics system.
   - From: `continuumAdInventoryService_smaMetricsLogger`
   - To: `continuumSmaMetrics`
   - Protocol: HTTP

9. **Return ad content**: `AdInventoryPlacementResource` returns the resolved ad content (or empty if no eligible audiences) to the frontend caller.
   - From: `continuumAdInventoryService_adInventoryPlacementResource`
   - To: Groupon Frontend
   - Protocol: REST / HTTP response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis cache miss | Audience target list returns empty; placement served without audience targeting | No ad served if no untargeted fallback exists |
| Redis unavailable | Guava in-memory cache used as fallback if populated; otherwise empty audience list | Possible degraded targeting; no exception surfaced to caller |
| Missing required parameter | HTTP 4xx returned by JAX-RS validation | Frontend receives error response |
| SMA metrics failure | Logged; non-blocking to placement serving | Metric gap; placement still returned |

## Sequence Diagram

```
Frontend -> AdInventoryPlacementResource: GET /ai/api/v1/placement?page=...&c_cookie=...
AdInventoryPlacementResource -> AudienceApi: getTargetedAudiences(request, adFormat)
AudienceApi -> Redis: get audienceTargetCache[placementId+country+format]
Redis --> AudienceApi: List<AudienceTargetContent>
AudienceApi -> Redis: get audienceCache[audienceId+segment] for each target
Redis --> AudienceApi: Audience (bloom filter)
AudienceApi -> AudienceApi: audience.isMember(bCookie, cCookie)
AudienceApi --> AdInventoryPlacementResource: List<AudienceTargetContent> (eligible)
AdInventoryPlacementResource -> SMAMetricsLogger: emit placement counter
SMAMetricsLogger -> SMAMetrics: HTTP submit
AdInventoryPlacementResource --> Frontend: ad content response
```

## Related

- Architecture dynamic view: `components-continuum-ad-inventory-service-components`
- Related flows: [Audience Cache Warm-Up](audience-cache-warm-up.md), [Sponsored Listing Click Tracking](sponsored-listing-click-tracking.md)
