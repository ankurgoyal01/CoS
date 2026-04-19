---
service: "gims"
title: "Image Upload Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "image-upload"
flow_type: synchronous
trigger: "Internal service uploads an image via GIMS REST API"
participants:
  - "continuumMetroDraftService"
  - "continuumMygrouponsService"
  - "continuumMessagingService"
  - "continuumMarketingEditorialContentService"
  - "continuumMediaService"
  - "gims"
  - "akamai-cdn"
architecture_ref: "containers-continuum-metro-draft"
---

# Image Upload Flow

## Summary

When an internal Continuum service needs to store an image — for a deal listing, a campaign, a merchant theme, or editorial content — it calls the GIMS REST API to upload the image. GIMS processes the upload, stores the original blob in its storage backend, creates metadata records, and makes the image available for retrieval and CDN delivery. Some upload flows use signed URLs for secure, time-limited upload authorization.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum services (Metro Draft, MyGroupons, Messaging, MECS, Media Service)
- **Frequency**: On demand (per image upload action by merchants, editors, or automated workflows)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream Service (e.g., Metro Draft) | Initiates image upload request | `continuumMetroDraftService` (or other consumer) |
| GIMS (Images Service) | Receives upload, stores blob and metadata, returns image reference | `gims` |
| Image Storage Backend | Persists the original image blob | (internal to GIMS) |
| Image Metadata Database | Stores image metadata, transformation records, and references | (internal to GIMS) |
| Akamai CDN | Caches and delivers the image to end users upon subsequent requests | (external) |

## Steps

1. **Initiate upload request**: The upstream service sends an HTTP request to GIMS with the image payload (file upload or URL reference) and associated metadata (content type, dimensions, context).
   - From: `continuumMetroDraftService` (or other consumer)
   - To: `gims`
   - Protocol: HTTP/REST (Retrofit for Metro Draft; HTTPS/JSON for MECS and others)

2. **Validate and process upload**: GIMS validates the upload request — checks file type, size limits, authentication, and metadata completeness.
   - From: `gims` (internal)
   - To: `gims` (internal)
   - Protocol: direct (in-process)

3. **Store original image blob**: GIMS writes the original image to its storage backend (object storage).
   - From: `gims`
   - To: Image Storage Backend
   - Protocol: Storage API (inferred)

4. **Create metadata record**: GIMS creates a metadata record for the image in its database, including storage path, dimensions, content type, upload context, and CDN-resolvable URL.
   - From: `gims`
   - To: Image Metadata Database
   - Protocol: SQL/JDBC (inferred)

5. **Return image reference**: GIMS returns the image ID, CDN-resolvable URL, and metadata to the calling service.
   - From: `gims`
   - To: `continuumMetroDraftService` (or other consumer)
   - Protocol: HTTP response (JSON)

6. **CDN availability**: The image is now available for delivery via Akamai CDN. On first request, Akamai performs an origin pull from GIMS; subsequent requests are served from edge cache.
   - From: Akamai CDN
   - To: `gims` (origin pull on cache miss)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid file type or size | GIMS rejects with 400 Bad Request | Upload fails; calling service displays validation error |
| Storage backend unavailable | GIMS returns 503 Service Unavailable | Upload fails; calling service retries or displays error |
| Authentication failure | GIMS returns 401/403 | Upload rejected; calling service logs auth error |
| Duplicate image | (inferred) GIMS may deduplicate or overwrite | Existing image reference returned or updated |
| Network timeout | Calling service receives timeout | Service-specific retry logic applies |

## Sequence Diagram

```
UpstreamService -> gims                : POST /images (upload payload + metadata)
gims            -> gims                : Validate file type, size, auth
gims            -> ImageStorageBackend : PUT original image blob
ImageStorageBackend --> gims           : Storage confirmation + path
gims            -> MetadataDatabase    : INSERT image metadata record
MetadataDatabase --> gims              : Record ID
gims            --> UpstreamService    : 201 Created (image ID, CDN URL, metadata)
...
Consumer        -> AkamaiCDN           : GET image URL
AkamaiCDN       -> gims                : Origin pull (cache miss only)
gims            --> AkamaiCDN          : Image bytes
AkamaiCDN       --> Consumer           : Cached image bytes
```

## Related

- Architecture dynamic view: `dynamic-media-upload-flow` (media-service interaction with GIMS)
- Related flows: [Image Retrieval and CDN Delivery](image-retrieval-cdn-delivery.md), [CDN Cache Priming](cdn-cache-priming.md)
