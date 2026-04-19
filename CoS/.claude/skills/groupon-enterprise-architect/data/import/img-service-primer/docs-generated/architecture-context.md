---
service: "img-service-primer"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumImageServicePrimer"
  containers: [continuumImageServicePrimer, continuumImageServicePrimerDb]
---

# Architecture Context

## System Context

Image Service Primer sits within the Continuum platform as a supporting utility to the Global Image Service (`gims`). It has no end-user-facing traffic. Its primary consumers are operators invoking manual preload endpoints and the internal Quartz scheduler. It depends on `continuumDealCatalogService` for deal metadata, on `gims` and `akamai` for cache warming, and on AWS S3 / GCS for video asset storage. A MySQL database (`continuumImageServicePrimerDb`) holds video transformation state. The service is identified in the service registry as `gims-primer`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Image Service Primer | `continuumImageServicePrimer` | Service | Java, JTier | 5.14.0 | Scheduled utility service that preloads image/video assets to warm Image Service and CDN caches |
| Image Service Primer DB | `continuumImageServicePrimerDb` | Database | MySQL | — | MySQL database storing video metadata and transformation state |

## Components by Container

### Image Service Primer (`continuumImageServicePrimer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `ImageResource` | Exposes image preload and cache priming endpoints (e.g. single-image prime, bulk image delete) | JAX-RS Resource |
| `PreloadResource` | Exposes preload trigger endpoints and immediate cron invocation | JAX-RS Resource |
| `DealCatalogFetchJob` | Quartz scheduled job; wakes once per day, fetches deals about to launch, starts priming pipeline | Quartz Job |
| `DealCatalogImageCollectingService` | Builds a deduplicated set of image URLs from deal-catalog API responses | Service |
| `ImagePreloadingService` | Expands images into transformation variants, issues preload requests to GIMS and Akamai | Service |
| `DealCatalogClient` | Retrofit HTTP client for deal-catalog search and deal metadata APIs | Retrofit Client |
| `ImageServiceClient` | Retrofit HTTP client for direct preload requests to GIMS | Retrofit Client |
| `AkamaiClient` | Retrofit HTTP client for Akamai CDN image fetches and cache warming | Retrofit Client |
| `VideoUpdateListener` | Consumes video transformation update events from the Groupon message bus | Message Listener |
| `VideoTransformer` | Downloads source media from GCS, transforms via ffmpeg/OpenCV, prepares upload artifacts | Service / Media |
| `S3VideoUploader` | Uploads transformed video payloads to AWS S3 | Utility / Storage |
| `VideoDao` | JDBI3 persistence component for video and transformation records in MySQL | JDBI DAO |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumImageServicePrimer` | `continuumImageServicePrimerDb` | Reads/writes video metadata and transformation state | JDBI/MySQL |
| `continuumImageServicePrimer` | `continuumDealCatalogService` | Fetches deals and image metadata to preload | HTTP/JSON |
| `continuumImageServicePrimer` | `gims` | Requests transformed and original images for cache priming | HTTP |
| `continuumImageServicePrimer` | `akamai` | Requests CDN URLs to warm edge cache | HTTPS |
| `continuumImageServicePrimer` | `akamai` | Issues cache purge/invalidation requests | HTTPS |

## Architecture Diagram References

- System context: `contexts-continuumImageServicePrimer`
- Container: `containers-continuumImageServicePrimer`
- Component: `components-continuumImageServicePrimer`
- Dynamic (daily image priming): `dynamic-daily-image-priming-flow`
- Dynamic (video transformation): `dynamic-video-transformation-flow`
