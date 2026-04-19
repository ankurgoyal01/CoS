---
service: "img-service-primer"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Global Image Service Primer.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Daily Image Priming](daily-image-priming.md) | scheduled | Quartz daily cron job (`DealCatalogFetchJob`) | Fetches deals launching within the next 24 hours from deal-catalog, deduplicates images, generates transformation variants, and warms GIMS and Akamai caches |
| [Manual Deal Preload](manual-deal-preload.md) | synchronous | Operator POST to preload endpoints | Allows operators to manually trigger image priming for specific deals, countries, or individual images outside of the scheduled run |
| [Image Delete](image-delete.md) | synchronous | Operator POST to `/v1/images` | Removes an image from S3 storage, GIMS nginx caches, and Akamai CDN storage |
| [Video Transformation](video-transformation.md) | event-driven | Video transformation update event consumed from message bus | Downloads source video from GCS, transforms via ffmpeg, persists state to MySQL, and uploads result to S3 |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The **Daily Image Priming** flow spans `continuumImageServicePrimer`, `continuumDealCatalogService`, `gims`, and `akamai`. Its architecture dynamic view is `dynamic-daily-image-priming-flow`.
- The **Video Transformation** flow spans `continuumImageServicePrimer`, the message bus (video transformation topic), GCS buckets, `continuumImageServicePrimerDb`, and AWS S3. Its architecture dynamic view is `dynamic-video-transformation-flow`.
