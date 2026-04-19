---
service: "barcode-service-app"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumBarcodeService"
  containers: ["continuumBarcodeService"]
---

# Architecture Context

## System Context

Barcode Service is a leaf-node service within the Continuum platform's Redemption domain. It has no outbound service calls — it receives inbound HTTP requests from any consumer requiring barcode images (voucher print pipelines, mobile apps, merchant portals) and returns rendered images entirely in-process. The service exposes versioned REST endpoints under the `/fubar/` path prefix (legacy internal routing alias) and `/v2/` prefix. It is deployed as a Kubernetes workload on AWS and GCP clusters across NA and EMEA regions, fronted by internal VIPs (`fubar-vip.snc1`, `fubar-vip.sac1`, `fubar-vip.dub1`).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Barcode Service | `continuumBarcodeService` | Backend Service | Java, Dropwizard, Guice | JTier 5.14.1 | Dropwizard/JTier service that generates barcode images for redemption and legacy flows. |

## Components by Container

### Barcode Service (`continuumBarcodeService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`barcodeSvc_apiResources`) | Exposes JAX-RS endpoints for barcode generation, width lookup, and code type/format discovery; routes requests to internal services | JAX-RS |
| Barcode Validation Service (`barcodeSvc_validationService`) | Validates incoming request payloads, dimension bounds, and rotation option values before generation proceeds | Java Service |
| Barcode Service (`barcodeSvc_generationService`) | Core barcode generation logic for standard and legacy (v1/v2) API flows | Java Service |
| JEDI Barcode Service (`barcodeSvc_jediGenerationService`) | JEDI-specific barcode generation with specialized sizing behavior for merchant center redemption URLs | Java Service |
| Barcode Size Policy (`barcodeSvc_sizePolicy`) | Encapsulates sizing rules, minimum height enforcement, and per-code-type dimension defaults and bounds | Java Helper |
| Barcode Rendering Engine (`barcodeSvc_renderingEngine`) | Concrete renderer implementations backed by ZXing and Barbecue; produces PNG or GIF image bytes | ZXing 3.3.3, Barbecue 1.5-beta1 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `barcodeSvc_apiResources` | `barcodeSvc_validationService` | Validates payload, dimensions, and rotation inputs | In-process (Java) |
| `barcodeSvc_apiResources` | `barcodeSvc_generationService` | Delegates standard barcode generation | In-process (Java) |
| `barcodeSvc_apiResources` | `barcodeSvc_jediGenerationService` | Delegates JEDI-specific barcode generation | In-process (Java) |
| `barcodeSvc_generationService` | `barcodeSvc_renderingEngine` | Selects renderer and renders barcode images | In-process (Java) |
| `barcodeSvc_jediGenerationService` | `barcodeSvc_renderingEngine` | Selects renderer and renders JEDI barcode images | In-process (Java) |
| `barcodeSvc_generationService` | `barcodeSvc_sizePolicy` | Applies barcode size bounds and defaults | In-process (Java) |
| `barcodeSvc_jediGenerationService` | `barcodeSvc_sizePolicy` | Applies JEDI size normalization rules | In-process (Java) |

## Architecture Diagram References

- Component view: `components-continuum-barcode-barcodeSvc_validationService`
- Dynamic view: `dynamic-barcode-generation-flow`
