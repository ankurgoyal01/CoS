---
service: "gims"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for GIMS (Groupon Image Management Service).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Image Upload](image-upload.md) | synchronous | Internal service uploads an image via GIMS API | An internal service (Metro Draft, MyGroupons, Messaging, MECS) uploads an image to GIMS, which stores the blob and metadata, and makes it available for CDN delivery |
| [Image Retrieval and CDN Delivery](image-retrieval-cdn-delivery.md) | synchronous | Consumer or service requests an image | A request for an image is served from Akamai CDN edge cache or falls back to GIMS origin for cache misses |
| [CDN Cache Priming](cdn-cache-priming.md) | scheduled | Image Service Primer runs scheduled priming job | The Image Service Primer proactively requests transformed and original images from GIMS to warm the Akamai CDN edge cache |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The **Image Upload** flow is initiated by multiple upstream services — Metro Draft Service, MyGroupons, Messaging Service, Marketing Editorial Content Service, and Media Service. Each uses GIMS as a shared image storage backend.
- The **Image Retrieval and CDN Delivery** flow involves Akamai CDN as the edge delivery layer and GIMS as the origin.
- The **CDN Cache Priming** flow is documented in the Image Service Primer's architecture as `dynamic-daily-image-priming`.
- The **Merchant Page map signing** flow is documented in merchant-page's architecture as `dynamic-merchant-page-request-flow`.
- The **Media upload** flow is documented in media-service's architecture as `dynamic-media-upload-flow`.
