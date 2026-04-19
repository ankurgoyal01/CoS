---
service: "img-service-primer"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 1
---

# Integrations

## Overview

Image Service Primer integrates with three external systems — Akamai CDN, AWS S3, and Google Cloud Storage — and one internal Groupon service, deal-catalog. All outbound integrations use HTTP or cloud SDK calls. GIMS (Global Image Service) is treated as an internal dependency accessed over HTTP. The service has no known programmatic upstream callers; its API surface is operator-triggered only.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Akamai CDN | HTTPS | Warm edge cache with deal images; purge stale images | Yes | `akamai` |
| AWS S3 | S3 API | Upload transformed video payloads; delete image assets | No | stub reference |
| Google Cloud Storage | GCS API | Download source video media; read transformed media references | No | stub reference |

### Akamai CDN Detail

- **Protocol**: HTTPS
- **Base URL**: `img.grouponcdn.com` (inferred from alert table in cloud owner's manual)
- **Auth**: Akamai EdgeGrid request signing via `edgegrid-signer-google-http-client` version 2.1.1
- **Purpose**: Two distinct uses — (1) pre-fetch image URLs to warm Akamai edge cache as part of daily priming; (2) issue purge/invalidation requests when images are deleted via `POST /v1/images`
- **Failure mode**: Akamai 5XX errors trigger PagerDuty alert "Akamai 5XX errors count"; operators should check ELK logs and contact info-sec team if persistent
- **Circuit breaker**: No evidence found in codebase of an explicit circuit breaker; parallelism is controlled via `rxConfig.schedulers` thread counts

### AWS S3 Detail

- **Protocol**: S3 API
- **SDK**: `software.amazon.awssdk:s3` version 2.26.25
- **Auth**: AWS SDK credential chain (credentials injected via Kubernetes secrets)
- **Purpose**: `S3VideoUploader` uploads transformed video artifacts; image delete flow removes assets
- **Failure mode**: Upload or delete failures are logged; no retry strategy documented in codebase
- **Circuit breaker**: No evidence found in codebase

### Google Cloud Storage Detail

- **Protocol**: GCS API
- **SDK**: `google-cloud-storage` via GCP BOM 26.44.0; custom `GCSClient` / `GCSClientManager` wrappers
- **Auth**: GCS service account credentials via `GCSServiceAccountCredentials`
- **Purpose**: `VideoTransformer` downloads source video from GCS before ffmpeg transformation; reads transformed media references after processing
- **Failure mode**: No evidence found in codebase of specific failure handling beyond standard SDK exceptions
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumDealCatalogService` (deal-catalog) | HTTP/JSON | Fetch list of scheduled deals and deal image metadata for upcoming distribution windows | `continuumDealCatalogService` |
| `gims` (Global Image Service) | HTTP | Pre-fetch original and transformed images to warm GIMS front and back caches | `gims` |

### deal-catalog (`continuumDealCatalogService`) Detail

- **Protocol**: HTTP/JSON
- **Client**: `DealCatalogClient` (Retrofit)
- **Purpose**: Called by `DealCatalogImageCollectingService` to search for scheduled deals and retrieve image metadata. Filtered by distribution window start (next 24 hours by default).
- **Failure mode**: deal-catalog 5XX errors trigger PagerDuty alert "Deal catalog 5XX errors count"; operators check ELK and report to deal-catalog team
- **Circuit breaker**: Parallelism controlled by `rxConfig.schedulers.dealCatalog.threadCount`; `defaultConfiguration.hitAkamai=false` and `defaultConfiguration.hitProcessedImages=false` can be set to reduce pressure on deal-catalog

### GIMS (`gims`) Detail

- **Protocol**: HTTP
- **Client**: `ImageServiceClient` (Retrofit)
- **Purpose**: Each image URL (original + transformed variants) is requested from GIMS to populate its in-memory caches ahead of deal traffic
- **Failure mode**: Overloading GIMS is a documented risk; operators can set `rxConfig.schedulers.imageService.threadCount=1` to throttle
- **Circuit breaker**: Thread-count-based concurrency limit via RxJava3 scheduler; no formal circuit breaker

## Consumed By

> Upstream consumers are tracked in the central architecture model. The API surface is internal/operator-only; no known programmatic callers exist.

## Dependency Health

- Outbound request latency and error rates for all dependencies are observable in Wavefront dashboards and Kibana/ELK logs using the Steno log sourcetype `image_service_primer`.
- Key Splunk queries for dependency health monitoring:
  - All outgoing requests by service: `index=misc sourcetype=image_service_primer name=http.out | timechart span=10s count by data.service`
  - Failed outgoing calls: `index=misc sourcetype=image_service_primer name=http.out data.status!=200`
  - p99 latency by service: `index=misc sourcetype=image_service_primer name=http.out | timechart span=1m avg(data.time.total), perc99(data.time.total) by data.service`
- Readiness and liveness health checks at `/grpn/healthcheck` (port 8080, 30-second interval, 180-second initial delay).
