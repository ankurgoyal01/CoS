---
service: "gims"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [gims]
---

# Architecture Context

## System Context

GIMS sits within the **Continuum** platform as Groupon's centralized image management service. It is a foundational shared-infrastructure service consumed by numerous upstream services that need to upload, retrieve, transform, or serve images. GIMS integrates with Akamai CDN for global edge delivery, enabling fast image loading across all Groupon consumer and merchant applications. The service is also being wrapped by the next-generation Encore platform's **Images** service (`encoreImages`) as part of the broader Continuum-to-Encore migration.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| GIMS (Images Service) | `gims` | Application | Java | (not specified) | Continuum service providing image storage and delivery; integrates with Akamai CDN for edge delivery |

## Components by Container

### GIMS (Images Service) (`gims`)

> No components defined in the architecture DSL. The GIMS model is currently a single container with no internal component decomposition. Component-level modeling should be added when the service source code is federated.

## Key Relationships

The following relationships are gathered from the federated architecture model across all consuming services:

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMetroDraftService` | `gims` | Uploads images and videos (signed URLs and media processing) | HTTP/Retrofit |
| `continuumMerchantPageService` | `gims` | Signs map image requests | HTTPS/JSON |
| `mapSigningAdapter` (component of merchant-page) | `gims` | Signs map image request | HTTPS/JSON |
| `continuumMygrouponsService` | `gims` | Uploads and retrieves custom theme assets | (not specified) |
| `continuumMessagingService` | `gims` | Uploads and resolves campaign image assets | (not specified) |
| `continuumMarketingEditorialContentService` | `gims` | Retrieves and uploads image assets | HTTPS/JSON |
| `continuumImageServicePrimer` | `gims` | Requests transformed and original images for cache priming | HTTP |
| `continuumMediaService` | `gims` | Calls media APIs for compatibility and retrieval | HTTP/REST |
| `mediaUploadOrchestrator` (component of media-service) | `gimsApiClient` | Uses GIMS-compatible upload and retrieval APIs | HTTP |
| `encoreImages` (Encore platform) | `gims` | Wraps GIMS for next-gen image management | (inferred) |

## Architecture Diagram References

- System context: Included in `contexts-continuum` (Continuum system-level)
- Container: Included in `containers-continuum-metro-draft` view
- Component: No component views defined for GIMS
- Dynamic views: No dynamic views defined for GIMS (see `dynamic-media-upload-flow` for media-service interaction, `dynamic-merchant-page-request-flow` for merchant-page interaction, `dynamic-daily-image-priming` for image primer interaction)
