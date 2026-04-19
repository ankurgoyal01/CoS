---
service: "merchant-page"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMerchantPageService]
---

# Architecture Context

## System Context

The merchant-page service is a container within the `continuumSystem` (Continuum Platform). It sits at the public-facing edge of the merchant discovery surface: the Routing Service directs `/biz/*` and `/merchant-page/*` traffic through the Hybrid Boundary to this service. The service orchestrates calls to four internal Continuum services — the Universal Merchant API, Relevance API, UGC Service, and GIMS map signer — assembles the full page model, and returns a server-rendered HTML response to the browser. It has no database of its own; all data is sourced synchronously from downstream services at request time.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Merchant Page Service | `continuumMerchantPageService` | WebApp | Node.js, Preact, itier-server | 7.14.2 | Server-rendered merchant place page service providing merchant details, reviews, maps, and deal card content. |

## Components by Container

### Merchant Page Service (`continuumMerchantPageService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Merchant Route Handler | Handles `GET /biz/{citySlug}/{merchantSlug}` requests; orchestrates all downstream calls and page composition | Node.js Route Controller |
| RAPI Route Handler | Serves `GET /merchant-page/rapi/{city}/{permalink}` requests; fetches and renders deal card HTML fragments | Node.js Route Controller |
| Reviews Route Handler | Serves `GET /merchant-page/reviews` requests; returns paginated UGC review JSON | Node.js Route Controller |
| Maps Route Handler | Serves `GET /merchant-page/maps/image` requests; generates a signed map image redirect URL | Node.js Route Controller |
| MPP Client Adapter | Fetches merchant and place data from `continuumUniversalMerchantApi` | Service Client Adapter |
| RAPI Client Adapter | Fetches related deal cards from `continuumRelevanceApi` | Service Client Adapter |
| UGC Client Adapter | Fetches merchant review content from `continuumUgcService` | Service Client Adapter |
| Map Signing Adapter | Generates signed map image URLs via `gims` | Service Client Adapter |
| Merchant View Renderer | Builds SSR merchant page markup and client hydration payloads using Preact | Preact SSR Renderer |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMerchantPageService` | `continuumUniversalMerchantApi` | Reads merchant and place data (lookup by city/merchant slug) | HTTPS/JSON |
| `continuumMerchantPageService` | `continuumRelevanceApi` | Reads related deal cards (cards search by category, lat/lon) | HTTPS/JSON |
| `continuumMerchantPageService` | `continuumUgcService` | Reads merchant reviews (paginated, with related aspects) | HTTPS/JSON |
| `continuumMerchantPageService` | `gims` | Signs static map image requests (redirects to signed map tile URL) | HTTPS/JSON |
| `continuumMerchantPageService` | `continuumApiLazloService` | Fetches proxied deal redirects when `proxy_deal` flag is enabled | HTTPS/JSON |
| `continuumMerchantPageService` | `loggingStack` | Writes application logs and traces in steno format | Structured logs |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumMerchantPageService`
- Dynamic (request flow): `dynamic-merchant-page-request-flow`
