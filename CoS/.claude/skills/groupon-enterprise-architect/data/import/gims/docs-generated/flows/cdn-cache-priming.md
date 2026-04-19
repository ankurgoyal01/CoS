---
service: "gims"
title: "CDN Cache Priming Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "cdn-cache-priming"
flow_type: scheduled
trigger: "Image Service Primer runs scheduled daily image priming job"
participants:
  - "continuumImageServicePrimer"
  - "gims"
  - "akamai-cdn"
architecture_ref: "dynamic-daily-image-priming"
---

# CDN Cache Priming Flow

## Summary

The Image Service Primer (`continuumImageServicePrimer`) runs a scheduled job to proactively warm the Akamai CDN cache for important images. It requests both transformed and original images from GIMS, causing the CDN to perform origin pulls and cache the responses at edge locations. This reduces cold-start latency for consumers viewing deal pages, merchant pages, and editorial content that contain newly uploaded or recently changed images.

## Trigger

- **Type**: schedule
- **Source**: Image Service Primer scheduled job (daily or periodic)
- **Frequency**: Daily (inferred from dynamic view name `daily-image-priming`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Image Service Primer | Orchestrates cache priming; requests images from GIMS at various transformation sizes | `continuumImageServicePrimer` |
| GIMS (Images Service) | Serves original and transformed images in response to priming requests | `gims` |
| Akamai CDN | Caches the served images at edge locations for subsequent consumer requests | (external) |

## Steps

1. **Primer job triggers**: The Image Service Primer scheduled job activates (daily or at configured interval).
   - From: `continuumImageServicePrimer` (scheduler)
   - To: `continuumImageServicePrimer` (internal)
   - Protocol: direct (scheduled trigger)

2. **Determine images to prime**: The primer identifies which images need cache warming — typically recently uploaded images, high-traffic deal images, or images approaching cache expiry.
   - From: `continuumImageServicePrimer` (internal)
   - To: `continuumImageServicePrimer` (internal)
   - Protocol: direct (in-process)

3. **Request transformed images from GIMS**: The primer's image service client requests each image at multiple transformation sizes (common viewport sizes, thumbnail sizes, etc.) from GIMS.
   - From: `continuumImageServicePrimer`
   - To: `gims`
   - Protocol: HTTP

4. **GIMS processes and returns images**: GIMS retrieves original blobs, applies transformations, and returns the image bytes. These responses flow through the CDN, causing edge caching.
   - From: `gims`
   - To: Akamai CDN (via normal CDN routing)
   - Protocol: HTTPS

5. **CDN caches at edge**: Akamai caches each transformed image variant at the relevant edge locations, making them available for fast consumer delivery.
   - From: Akamai CDN
   - To: Akamai CDN (edge storage)
   - Protocol: CDN internal

6. **Request original images from GIMS**: The primer also requests original (untransformed) images to warm the cache for direct-link access.
   - From: `continuumImageServicePrimer`
   - To: `gims`
   - Protocol: HTTP

7. **Priming job completes**: The primer logs completion metrics — number of images primed, success/failure counts, total duration.
   - From: `continuumImageServicePrimer` (internal)
   - To: Logging/Metrics
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GIMS unavailable | Primer logs error; skips image or retries | Images not primed; consumers experience CDN cache misses (slower first load) |
| Image not found (404) | Primer logs warning; skips image | Stale or deleted image reference; primer continues with remaining images |
| Transformation timeout | Primer logs error; may retry with smaller batch | Some transformations not cached; consumers trigger origin pull on demand |
| CDN edge not accepting cache | CDN configuration issue | Images served but not cached; no priming benefit; investigate CDN config |
| Primer job timeout | Job fails after configured duration | Partial priming; remaining images handled by on-demand origin pulls |

## Sequence Diagram

```
[Scheduled trigger]
ImageServicePrimer -> ImageServicePrimer : Determine images to prime
loop For each image to prime
    loop For each transformation size
        ImageServicePrimer -> gims           : GET /image/{id}?w={width}&h={height}
        gims               -> StorageBackend : GET original blob
        StorageBackend     --> gims           : original bytes
        gims               -> gims           : apply transformation
        gims               --> AkamaiCDN     : transformed image (via CDN routing)
        AkamaiCDN          --> ImageServicePrimer : image bytes (now cached at edge)
    end
    ImageServicePrimer -> gims               : GET /image/{id} (original)
    gims               --> AkamaiCDN         : original image (via CDN routing)
    AkamaiCDN          --> ImageServicePrimer : image bytes (now cached at edge)
end
ImageServicePrimer -> Metrics                : Log priming results
```

## Related

- Architecture dynamic view: `dynamic-daily-image-priming` (Image Service Primer architecture)
- Related flows: [Image Upload](image-upload.md), [Image Retrieval and CDN Delivery](image-retrieval-cdn-delivery.md)
