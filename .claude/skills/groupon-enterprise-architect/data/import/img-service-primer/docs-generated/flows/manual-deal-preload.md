---
service: "img-service-primer"
title: "Manual Deal Preload"
generated: "2026-03-03"
type: flow
flow_name: "manual-deal-preload"
flow_type: synchronous
trigger: "Operator HTTP POST to a preload endpoint"
participants:
  - "preloadResource"
  - "imageResource"
  - "imagePreloadingService"
  - "imgServicePrimer_dealCatalogClient"
  - "imageServiceClient"
  - "akamaiClient"
  - "continuumDealCatalogService"
  - "gims"
  - "akamai"
architecture_ref: "components-continuumImageServicePrimer"
---

# Manual Deal Preload

## Summary

The manual deal preload flow allows operators to trigger image cache priming outside of the daily scheduled run. It supports several targeting modes: a specific deal by UUID, a batch of deals or countries, a specific country, or a specific image by its GIMS client/SHA/rootName coordinates. The operator posts to the appropriate REST endpoint; the request is accepted and the priming pipeline runs with the same logic as the scheduled flow but scoped to the specified target. All preload endpoints accept an optional `ExecutionConfiguration` block to override default behavior (which caches to hit, which transformation codes to apply, etc.).

## Trigger

- **Type**: api-call
- **Source**: Operator or internal tooling via HTTP POST
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `PreloadResource` | Receives preload trigger requests; delegates to `ImagePreloadingService` | `preloadResource` |
| `ImageResource` | Receives image-scoped preload requests | `imageResource` |
| `ImagePreloadingService` | Generates transformation variants; dispatches preload requests | `imagePreloadingService` |
| `DealCatalogClient` | Fetches deal/image metadata when deal UUID or country code is specified | `imgServicePrimer_dealCatalogClient` |
| `ImageServiceClient` | Pre-fetches images from GIMS | `imageServiceClient` |
| `AkamaiClient` | Warms Akamai CDN edge cache | `akamaiClient` |
| deal-catalog | Source of deal and image metadata | `continuumDealCatalogService` |
| GIMS | Image service whose caches are being warmed | `gims` |
| Akamai CDN | CDN whose edge cache is being warmed | `akamai` |

## Steps

### Variant A: Immediate cron trigger (`POST /v1/preload/cron/immediately`)

1. **Receive request**: `PreloadResource` accepts the POST request.
   - From: Operator / calling tool
   - To: `preloadResource`
   - Protocol: REST/HTTP

2. **Delegate to pipeline**: `PreloadResource` triggers `ImagePreloadingService` with the same parameters as the scheduled daily run.
   - From: `preloadResource`
   - To: `imagePreloadingService`
   - Protocol: direct (in-process)

3. **Execute full priming pipeline**: Same steps as [Daily Image Priming](daily-image-priming.md) steps 2–7.

### Variant B: Deal-scoped trigger (`POST /v1/preload/deal/{dealUuid}`)

1. **Receive request**: `PreloadResource` accepts the POST with a deal UUID path parameter.
   - From: Operator
   - To: `preloadResource`
   - Protocol: REST/HTTP

2. **Fetch deal metadata**: `DealCatalogClient` retrieves image metadata for the specified deal UUID from deal-catalog.
   - From: `imagePreloadingService`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP/JSON

3. **Expand transforms and preload**: `ImagePreloadingService` generates transformation variants and issues GIMS and Akamai requests as per the standard pipeline.
   - From: `imagePreloadingService`
   - To: `gims`, `akamai`
   - Protocol: HTTP / HTTPS

### Variant C: Country-scoped trigger (`POST /v1/preload/country/{cc}`)

1. **Receive request**: `PreloadResource` accepts the POST with a 2-letter country code.
2. **Search deals by country**: `DealCatalogClient` queries deal-catalog for all scheduled deals in the specified country.
3. **Deduplicate and preload**: Same deduplication and priming steps as the scheduled flow but scoped to the country.

### Variant D: Image-scoped trigger (`POST /v1/preload/image/{client}/{sha}/{rootName}`)

1. **Receive request**: `ImageResource` accepts the POST with image coordinates (client, GIMS SHA, root name).
2. **Generate variants**: `ImagePreloadingService` constructs all transformation URLs directly from the image coordinates without calling deal-catalog.
3. **Preload from GIMS and Akamai**: Issues pre-fetch requests for all transformation variants.

### Variant E: Batch deal/country trigger (`POST /v1/preload/deal`)

1. **Receive request**: `PreloadResource` accepts the POST with a `MultiDealsRequest` body specifying a list of deal UUIDs or country codes plus an optional `ExecutionConfiguration` override.
2. **Process each target**: Iterates over the specified deals or countries, fetching metadata and running the priming pipeline per target.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid deal UUID | deal-catalog returns 404 or 400 | Request fails; operator should verify UUID |
| deal-catalog unavailable | HTTP error returned from `DealCatalogClient` | Priming aborted for affected deals |
| GIMS or Akamai errors | Logged; other images continue | Partial priming; operator may retry the specific deal |

## Sequence Diagram

```
Operator -> PreloadResource: POST /v1/preload/deal/{dealUuid}
PreloadResource -> ImagePreloadingService: Trigger preload for deal
ImagePreloadingService -> DealCatalogClient: Fetch image metadata for dealUuid
DealCatalogClient -> continuumDealCatalogService: GET deal by UUID (HTTP/JSON)
continuumDealCatalogService --> DealCatalogClient: Deal image metadata
DealCatalogClient --> ImagePreloadingService: Image URLs
ImagePreloadingService -> ImageServiceClient: GET each image variant from GIMS
ImageServiceClient -> gims: HTTP GET (per transform)
gims --> ImageServiceClient: Image response (cache populated)
ImagePreloadingService -> AkamaiClient: GET each image variant from Akamai
AkamaiClient -> akamai: HTTPS GET
akamai --> AkamaiClient: CDN response (edge cache populated)
```

## Related

- Architecture component view: `components-continuumImageServicePrimer`
- Related flows: [Daily Image Priming](daily-image-priming.md), [Image Delete](image-delete.md)
- API reference: [API Surface](../api-surface.md) — preload endpoints
