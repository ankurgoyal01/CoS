---
service: "coupons-ui"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumCouponsUi"
    - "continuumCouponsRedis"
    - "continuumCouponsMemoryCache"
---

# Architecture Context

## System Context

Coupons UI is a container within the `continuumSystem` (Continuum platform). It sits at the browser-facing edge of the Coupons domain: nginx receives inbound HTTP requests on port 8080, rewrites `/coupons/*` paths, and forwards them to the Astro Node.js server running on port 3000. The service reads pre-populated coupon data from a Redis cache, calls the external VoucherCloud API for live redemption and redirect operations, and injects Google Tag Manager for analytics. Logs are forwarded asynchronously to the centralized Logging Stack; metrics are emitted to the Metrics Stack via Telegraf/InfluxDB.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Coupons UI | `continuumCouponsUi` | WebApp | TypeScript, Astro, Svelte | Astro SSR application serving coupon pages and API handlers; orchestrates request context, logging, caching, and integrations |
| Coupons Redis Cache | `continuumCouponsRedis` | Cache / Database | Redis | Redis cache holding merchant page payloads and site-wide coupon data consumed by the UI |
| Coupons Memory Cache | `continuumCouponsMemoryCache` | Cache / Database | NodeCache | Process-local NodeCache buffering site-wide coupon data to reduce Redis reads |

## Components by Container

### Coupons UI (`continuumCouponsUi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Runtime Middleware | Initializes config, request context, logging, caches, Redis, and VoucherCloud clients per request | TypeScript, Astro middleware |
| Configuration Loader | Loads and merges base + region YAML configs; interpolates environment variables at startup | TypeScript, js-yaml |
| Request Context Factory | Builds request-scoped context (request ID, country code, locale, headers) attached to Astro locals | TypeScript |
| Logger Factory & Writers | Creates structured loggers per request with file and console writers and timing support | TypeScript |
| In-Memory Cache Manager | NodeCache-backed `getOrElse` helper for site-wide data with TTL and background refresh | TypeScript, NodeCache |
| Redis Factory & Client | Manages a shared ioredis connection and typed client for JSON reads with structured logging | TypeScript, ioredis |
| VoucherCloud Cache Client | Retrieves merchant pages and site-wide coupon data from Redis using country-aware keys | TypeScript |
| HTTP Client (Got) | Shared got-based HTTP client with retries, timeouts, and request logging | TypeScript, got |
| VoucherCloud API Adapter | Encapsulates VoucherCloud API operations: redemption, redirects, merchant redirects, click bulk updates | TypeScript |
| Redemption API Handler | Server route `/api/redemption/{offerId}` forwarding redemption requests to VoucherCloud API | TypeScript, Astro API |
| Redirect API Handler | Server route `/api/redirect/{offerId}` fetching affiliate redirect URLs from VoucherCloud API | TypeScript, Astro API |
| Healthcheck Endpoint | Route `/grpn/healthcheck` responding with `OK` for infrastructure probes | TypeScript, Astro API |
| Merchant Page Renderer | SSR Astro page composing merchant data, offers, SEO metadata, and Svelte widgets | Astro, Svelte |
| Redemption Orchestrator (Client) | Client-side workflow managing redemption calls, modal rendering, and redirect handling | TypeScript, Svelte |
| Algolia Search Input | Client-side search widget querying Algolia indices for merchant suggestions | Svelte, Algolia JS client |
| Google Tag Manager Integration | Astro component injecting GTM scripts/noscript when enabled in config | Astro |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCouponsUi` | `continuumCouponsRedis` | Reads merchant pages and site-wide coupon datasets | Redis protocol |
| `continuumCouponsUi` | `continuumCouponsMemoryCache` | Stores site-wide content temporarily to reduce Redis lookups | In-memory |
| `continuumCouponsUi` | `voucherCloudApi` | Fetches redirect and redemption information | HTTPS |
| `continuumCouponsUi` | `googleTagManager` | Serves GTM integration to browser | JavaScript |
| `continuumCouponsUi` | `loggingStack` | Writes application logs asynchronously | Async file |
| `continuumCouponsUi` | `metricsStack` | Publishes service metrics via Telegraf/InfluxDB | Stats/OTel |
| `continuumCouponsUi_voucherCloudCacheClient` | `continuumCouponsRedis` | Reads merchant page and site-wide data via Redis client | Redis protocol |
| `continuumCouponsUi_voucherCloudCacheClient` | `continuumCouponsMemoryCache` | Caches site-wide data with TTL | In-memory |
| `continuumCouponsUi_redemptionApi` | `voucherCloudApi` | Fetches redemption payloads for offers | HTTPS |
| `continuumCouponsUi_redirectApi` | `voucherCloudApi` | Obtains affiliate redirect URL for an offer | HTTPS |
| `continuumCouponsUi_redemptionOrchestrator` | `continuumCouponsUi_redemptionApi` | Calls redemption endpoint for offer data | REST (browser fetch) |
| `continuumCouponsUi_redemptionOrchestrator` | `continuumCouponsUi_redirectApi` | Requests redirect URL before opening affiliate link | REST (browser fetch) |

## Architecture Diagram References

- Component view: `components-continuum-coupons-ui`
- Dynamic view: `dynamic-coupons-ui-request-redemption-flow`
