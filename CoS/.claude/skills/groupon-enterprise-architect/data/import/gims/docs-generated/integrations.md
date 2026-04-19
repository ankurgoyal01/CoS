---
service: "gims"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

GIMS has one critical external dependency — Akamai CDN for edge delivery of images. It does not have documented internal downstream dependencies in the architecture model (it is itself a foundational service). GIMS is consumed by at least 8 internal Continuum services and is being wrapped by the Encore platform's Images service as part of the platform migration.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Akamai CDN | HTTPS | Edge caching and global delivery of images | yes | (external) |

### Akamai CDN Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: CDN edge endpoints configured for Groupon image domains
- **Auth**: CDN-level configuration (token auth or origin pull headers, inferred)
- **Purpose**: Caches and delivers images from GIMS origin servers to end users globally, reducing latency and origin load
- **Failure mode**: If Akamai is unavailable, image delivery degrades — consumers see broken images or slow loading. Origin servers would receive all traffic directly.
- **Circuit breaker**: CDN-level failover (Akamai infrastructure handles this)

## Internal Dependencies

> No evidence found in codebase for downstream internal dependencies owned by GIMS. The service appears to be a leaf node in the dependency graph — it stores and serves images without calling other Continuum services.

## Consumed By

The following services consume GIMS APIs based on the federated architecture model:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Metro Draft Service (`continuumMetroDraftService`) | HTTP/Retrofit | Uploads images and videos (signed URLs and media processing) |
| Merchant Page Service (`continuumMerchantPageService`) | HTTPS/JSON | Signs map image requests |
| MyGroupons Service (`continuumMygrouponsService`) | (not specified) | Uploads and retrieves custom theme assets |
| Messaging Service (`continuumMessagingService`) | (not specified) | Uploads and resolves campaign image assets |
| Marketing Editorial Content Service (`continuumMarketingEditorialContentService`) | HTTPS/JSON | Retrieves and uploads image assets |
| Image Service Primer (`continuumImageServicePrimer`) | HTTP | Requests transformed and original images for cache priming |
| Media Service (`continuumMediaService`) | HTTP/REST | Calls media APIs for compatibility and retrieval |
| UGC Async Service (`continuumUgcAsyncService`) | (commented out) | Reads image metadata |
| Encore Images (`encoreImages`) | (inferred) | Next-gen wrapper for GIMS on the Encore platform |

## Dependency Health

> No evidence found in codebase. Health check and retry patterns should be documented by the service owner. CDN health is monitored via Akamai's own observability tooling.
