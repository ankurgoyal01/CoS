---
service: "gims"
title: "Image Retrieval and CDN Delivery Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "image-retrieval-cdn-delivery"
flow_type: synchronous
trigger: "Consumer or internal service requests an image by URL"
participants:
  - "consumer-browser"
  - "akamai-cdn"
  - "gims"
architecture_ref: "containers-continuum-metro-draft"
---

# Image Retrieval and CDN Delivery Flow

## Summary

When a consumer's browser or an internal service requests an image, the request is routed through Akamai CDN. If the image is cached at the edge, Akamai serves it directly with minimal latency. On a cache miss, Akamai performs an origin pull from GIMS, which retrieves the image from its storage backend, optionally applies transformations (resize, crop, format conversion), and returns it to Akamai for caching and delivery. This flow also covers internal services that retrieve images or image metadata directly from GIMS, such as the Image Service Primer for cache warming and the Media Service for compatibility retrieval.

## Trigger

- **Type**: user-action / api-call
- **Source**: Consumer browser loading a page with images; internal services retrieving image data
- **Frequency**: High volume — per page load for consumers; on demand for internal services

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer Browser | End user viewing a Groupon page with images | (external) |
| Akamai CDN | Edge cache and delivery network; serves cached images or performs origin pulls | (external) |
| GIMS (Images Service) | Origin server; retrieves and optionally transforms images from storage | `gims` |
| Image Storage Backend | Persistent storage for original image blobs | (internal to GIMS) |
| Image Service Primer (optional) | Proactively requests images to warm CDN cache | `continuumImageServicePrimer` |
| Merchant Page Service (optional) | Requests signed map images | `continuumMerchantPageService` |

## Steps

### CDN-served image retrieval (cache hit)

1. **Consumer requests image**: The consumer's browser makes an HTTP GET request for an image URL (e.g., embedded in a deal page, merchant page, or editorial content).
   - From: Consumer Browser
   - To: Akamai CDN
   - Protocol: HTTPS

2. **CDN serves from cache**: Akamai has the image cached at the nearest edge location and serves it directly.
   - From: Akamai CDN
   - To: Consumer Browser
   - Protocol: HTTPS response (image bytes, cache headers)

### Origin pull (cache miss)

1. **Consumer requests image**: Same as above — HTTP GET for an image URL.
   - From: Consumer Browser
   - To: Akamai CDN
   - Protocol: HTTPS

2. **CDN origin pull**: Akamai does not have the image cached and forwards the request to the GIMS origin.
   - From: Akamai CDN
   - To: `gims`
   - Protocol: HTTPS

3. **GIMS resolves image**: GIMS looks up the image metadata (ID, storage path, transformation parameters) in its database.
   - From: `gims`
   - To: Image Metadata Database
   - Protocol: SQL/JDBC (inferred)

4. **GIMS retrieves blob**: GIMS fetches the original image blob from object storage.
   - From: `gims`
   - To: Image Storage Backend
   - Protocol: Storage API (inferred)

5. **GIMS applies transformations** (if requested): If the URL specifies transformation parameters (resize, crop, format), GIMS processes the image.
   - From: `gims` (internal)
   - To: `gims` (internal)
   - Protocol: direct (in-process)

6. **GIMS returns image to CDN**: GIMS returns the image bytes with appropriate cache headers.
   - From: `gims`
   - To: Akamai CDN
   - Protocol: HTTPS response

7. **CDN caches and delivers**: Akamai caches the image at the edge and delivers it to the consumer.
   - From: Akamai CDN
   - To: Consumer Browser
   - Protocol: HTTPS response

### Direct internal retrieval

1. **Internal service requests image**: An internal service (e.g., Media Service, Image Service Primer) calls GIMS REST API directly.
   - From: `continuumMediaService` or `continuumImageServicePrimer`
   - To: `gims`
   - Protocol: HTTP/REST

2. **GIMS returns image or metadata**: GIMS retrieves and returns the requested image data or metadata.
   - From: `gims`
   - To: Calling service
   - Protocol: HTTP response (JSON or image bytes)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CDN cache miss — origin healthy | Akamai performs origin pull; caches response | Slightly higher latency for first request; subsequent requests served from cache |
| CDN cache miss — origin down | Akamai serves stale content (if available) or returns error | Consumer sees broken image or placeholder; CDN may serve stale cached version |
| Image not found | GIMS returns 404 | CDN returns 404 to consumer; broken image placeholder displayed |
| Transformation failure | GIMS returns 500 or serves original untransformed image | Consumer may see original-size image or error |
| Storage backend timeout | GIMS returns 504 | CDN retries or returns error; consumer sees broken image |

## Sequence Diagram

```
ConsumerBrowser -> AkamaiCDN          : GET /image/12345?w=300&h=200
alt Cache Hit
    AkamaiCDN   --> ConsumerBrowser   : 200 (cached image bytes)
else Cache Miss
    AkamaiCDN   -> gims               : GET /image/12345?w=300&h=200 (origin pull)
    gims        -> MetadataDatabase   : SELECT image metadata
    MetadataDatabase --> gims          : metadata (storage path, params)
    gims        -> ImageStorageBackend: GET original blob
    ImageStorageBackend --> gims       : original image bytes
    gims        -> gims               : apply transformations (resize 300x200)
    gims        --> AkamaiCDN          : 200 (transformed image bytes + cache headers)
    AkamaiCDN   --> ConsumerBrowser   : 200 (image bytes)
end
```

## Related

- Architecture dynamic view: `dynamic-merchant-page-request-flow` (merchant page map image signing via GIMS)
- Related flows: [Image Upload](image-upload.md), [CDN Cache Priming](cdn-cache-priming.md)
