---
service: "img-service-primer"
title: "Daily Image Priming"
generated: "2026-03-03"
type: flow
flow_name: "daily-image-priming"
flow_type: scheduled
trigger: "Quartz scheduled job fires once per day (DealCatalogFetchJob)"
participants:
  - "dealCatalogFetchJob"
  - "dealCatalogImageCollectingService"
  - "imgServicePrimer_dealCatalogClient"
  - "imagePreloadingService"
  - "imageServiceClient"
  - "akamaiClient"
  - "continuumDealCatalogService"
  - "gims"
  - "akamai"
architecture_ref: "dynamic-daily-image-priming-flow"
---

# Daily Image Priming

## Summary

The daily image priming flow is the core scheduled operation of Image Service Primer. Once per day the Quartz scheduler wakes `DealCatalogFetchJob`, which orchestrates a full priming cycle: it queries deal-catalog for deals scheduled to launch within the next 24-hour distribution window, builds a deduplicated set of images from those deals, expands each image into all configured transformation variants, and then issues pre-fetch HTTP requests against both GIMS and Akamai. This ensures that when real user traffic hits newly launched deals, all three cache layers (Akamai edge, GIMS front cache, GIMS back cache) are already warm, preventing the 10–20 second cold-start latency spikes otherwise observed.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (`jtier-quartz-bundle`), in-memory job store
- **Frequency**: Once per day (daily); can also be triggered immediately via `POST /v1/preload/cron/immediately`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `DealCatalogFetchJob` | Initiates the daily priming cycle; delegates to collecting service | `dealCatalogFetchJob` |
| `DealCatalogImageCollectingService` | Queries deal-catalog, filters deals by distribution window, deduplicates images | `dealCatalogImageCollectingService` |
| `DealCatalogClient` | Retrofit HTTP client — executes searchDeals and getDeal API calls | `imgServicePrimer_dealCatalogClient` |
| `ImagePreloadingService` | Generates transformation URL variants; dispatches preload requests | `imagePreloadingService` |
| `ImageServiceClient` | Retrofit HTTP client — pre-fetches images from GIMS | `imageServiceClient` |
| `AkamaiClient` | Retrofit HTTP client — warms Akamai CDN edge cache | `akamaiClient` |
| deal-catalog | External source of deal and image metadata | `continuumDealCatalogService` |
| GIMS | Image service whose caches are being warmed | `gims` |
| Akamai CDN | CDN whose edge cache is being warmed | `akamai` |

## Steps

1. **Scheduler fires**: Quartz triggers `DealCatalogFetchJob` once per day.
   - From: `DealCatalogFetchJob` (Quartz scheduler)
   - To: `DealCatalogImageCollectingService`
   - Protocol: direct (in-process)

2. **Fetch scheduled deals**: `DealCatalogImageCollectingService` calls `DealCatalogClient` to search for deals in `scheduled` status via the deal-catalog search API.
   - From: `DealCatalogImageCollectingService`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP/JSON (via Retrofit `DealCatalogClient`)

3. **Filter by distribution window**: The collecting service filters the deal result set to retain only deals whose distribution window starts within the next 24 hours (configurable via `distroWindowInDays`).
   - From: `DealCatalogImageCollectingService` (in-process filter)
   - To: in-process

4. **Deduplicate images**: The collecting service extracts image references from the filtered deals and deduplicates them into a single image set.
   - From: `DealCatalogImageCollectingService`
   - To: `ImagePreloadingService`
   - Protocol: direct (in-process, via RxJava3 reactive stream)

5. **Generate transformation variants**: `ImagePreloadingService` expands each unique image URL into a full list of transformed image URLs based on the configured transformation codes (up to 100 transformation codes per image), plus the original un-transformed URL.
   - From: `ImagePreloadingService` (in-process)

6. **Pre-fetch from GIMS**: For each image URL (original + all transformed variants), `ImagePreloadingService` issues an HTTP GET request via `ImageServiceClient` to GIMS. This populates the GIMS front and back caches.
   - From: `imagePreloadingService`
   - To: `gims`
   - Protocol: HTTP (via Retrofit `ImageServiceClient`)

7. **Warm Akamai edge cache**: Concurrently with (or after) the GIMS requests, `ImagePreloadingService` issues equivalent HTTP requests via `AkamaiClient` to the Akamai CDN. This populates the Akamai edge cache for all transformed URLs.
   - From: `imagePreloadingService`
   - To: `akamai`
   - Protocol: HTTPS (via Retrofit `AkamaiClient`)

8. **Log completion**: A `log-done` trace event is written to the Steno log (`index=misc sourcetype=image_service_primer`) recording success counts, failure counts, and the trigger source (`CRON`).

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| deal-catalog search returns 5XX | Logged as HTTP out failure; priming run may complete with zero deals | `primer_execution_stats` Nagios alert fires if failure rate is too high |
| GIMS returns error on image fetch | Logged; RxJava3 backpressure prevents cascade | Individual image priming fails silently; run continues |
| Akamai returns 5XX | Logged; run continues | "Akamai 5XX errors count" alert fires in Wavefront |
| Too many concurrent requests | `primer_high-water-mark` alert fires | Operator restarts the service or reduces thread counts via config |
| Application OOM (> ~10k deals) | Container OOM kill; pod restart | Unexpected during normal operations; restart resolves |

## Sequence Diagram

```
DealCatalogFetchJob -> DealCatalogImageCollectingService: Start scheduled preload run
DealCatalogImageCollectingService -> DealCatalogClient: Fetch deals scheduled in next distro window
DealCatalogClient -> continuumDealCatalogService: GET searchDeals (HTTP/JSON)
continuumDealCatalogService --> DealCatalogClient: Deal list + image metadata
DealCatalogClient --> DealCatalogImageCollectingService: Deal + image results
DealCatalogImageCollectingService -> DealCatalogImageCollectingService: Filter by distro window; deduplicate images
DealCatalogImageCollectingService -> ImagePreloadingService: Send deduplicated image URLs + transforms
ImagePreloadingService -> ImageServiceClient: Request images from GIMS (per transform variant)
ImageServiceClient -> gims: GET /v1/{transformCode}/{imageRef} (HTTP)
gims --> ImageServiceClient: Image response (cache populated)
ImagePreloadingService -> AkamaiClient: Request equivalent CDN URLs
AkamaiClient -> akamai: GET img.grouponcdn.com/... (HTTPS)
akamai --> AkamaiClient: CDN response (edge cache populated)
```

## Related

- Architecture dynamic view: `dynamic-daily-image-priming-flow`
- Related flows: [Manual Deal Preload](manual-deal-preload.md), [Image Delete](image-delete.md)
- Configuration: [Configuration](../configuration.md) — `imageTransforms`, `hitAkamai`, `hitProcessedImages`, `rxConfig.schedulers`
