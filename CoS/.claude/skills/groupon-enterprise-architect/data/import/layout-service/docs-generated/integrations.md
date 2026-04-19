---
service: "layout-service"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

Layout Service has a focused integration footprint: one internal data store (Redis cache) and one external infrastructure dependency (CDN for static asset resolution). It does not integrate with third-party SaaS systems or other Continuum microservices at runtime beyond these two dependencies. Upstream consumers are all Groupon i-tier frontend applications.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| CDN (static asset origin) | HTTPS / asset resolution | Provides resolved URLs for brand-specific static assets (JS, CSS, images) injected into layout templates | yes | — |

### CDN Detail

- **Protocol**: HTTPS asset resolution; `layoutSvc_assetResolver` generates CDN-backed URLs for static resources
- **Base URL / SDK**: Asset base URL injected via environment configuration; resolved at startup or per-request by `layoutSvc_assetResolver`
- **Auth**: No auth required for public CDN asset URLs; internal asset manifests may require service configuration
- **Purpose**: Ensures all static assets (scripts, stylesheets, images) referenced in header/footer templates resolve to the correct CDN-backed URL for the current deployment/brand
- **Failure mode**: Layout responses may include broken asset URLs or fall back to uncached asset paths; page chrome remains structurally available
- **Circuit breaker**: No evidence found — asset URL resolution is performed locally using pre-loaded manifests; no outbound HTTP call to CDN at render time

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Layout Template Cache | Redis protocol | Read and write compiled templates and rendered fragments | `continuumLayoutTemplateCache` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon i-tier frontend applications | REST (HTTP GET `/layout/*`) | Obtain rendered page chrome (header, footer, navigation) for server-side page composition |

> Upstream consumers are tracked in the central architecture model. All Groupon i-tier apps are expected consumers; specific service identifiers are maintained in the Continuum platform model.

## Dependency Health

- **Redis (`continuumLayoutTemplateCache`)**: Layout Service treats Redis as a non-blocking performance enhancement. A Redis failure degrades to cache-miss behavior — templates are re-compiled and fragments re-rendered on every request, increasing CPU and latency, but the service remains functional.
- **CDN**: Asset URLs are resolved from locally available manifests. CDN unavailability does not block layout rendering; it only affects asset delivery to end-user browsers, which is outside Layout Service's responsibility boundary.
