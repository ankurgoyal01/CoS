---
service: "goods-inventory-service-routing"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 1
---

# Integrations

## Overview

This service has one internal downstream dependency: the multi-regional `continuumGoodsInventoryService`. All inbound requests are proxied to a specific regional GIS instance resolved by the routing logic. There are no external third-party integrations or SaaS dependencies. Infrastructure dependencies (PostgreSQL via DaaS, Kubernetes, Hybrid Boundary) are platform-level concerns addressed in [Configuration](configuration.md) and [Deployment](deployment.md).

## External Dependencies

> No evidence found in codebase. No external (third-party or SaaS) HTTP/gRPC/SDK integrations are used.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Goods Inventory Service | HTTP (OkHttp) | Receives proxied inventory product read, upsert, and update requests; owns the canonical inventory data | `continuumGoodsInventoryService` |

### Goods Inventory Service (`continuumGoodsInventoryService`) Detail

- **Protocol**: HTTP (plain, no TLS between internal services)
- **Base URL**: Resolved at runtime from `gisRegions[*].gisUrl` config (e.g., `goods-inventory-service.production.service` or `goods-inventory-service.staging.service`)
- **Endpoint proxied**: `http://{gisUrl}/inventory/v1/products[/{uuid}]`
- **Auth**: Internal network trust; no token or API key exchanged between GISR and GIS
- **Purpose**: GISR forwards all validated inventory product requests to the appropriate regional GIS instance and streams the response (status code + body) back to the caller
- **Request headers**: All caller headers are forwarded except `host` and `accept-encoding`; the `X-HB-Region` header is injected with the resolved hybrid-boundary region value
- **Failure mode**: If the OkHttp call throws an `IOException`, GISR returns HTTP 500 with error code `UNABLE_TO_REACH_GIS`. No retry or circuit-breaker logic is implemented at the application level.
- **Circuit breaker**: No evidence found in codebase.

### Configured GIS Regions

| Region Name | GIS URL (Production) | GIS URL (Staging) | Hybrid Boundary Region | Shipping Regions |
|-------------|---------------------|-------------------|----------------------|-----------------|
| NA | `goods-inventory-service.production.service` | `goods-inventory-service.staging.service` | `us-central1` | US, CA |
| EMEA | `goods-inventory-service.production.service` | `goods-inventory-service.staging.service` | `eu-west-1` (prod) / `europe-west1` (staging) | GB, IT, FR, DE, ES, IE, BE, NL |

## Consumed By

> Upstream consumers are tracked in the central architecture model. This service is an internal routing layer; it is called by other Groupon backend services that manage inventory products without awareness of regional GIS topology.

## Dependency Health

The service uses a Dropwizard `HealthCheck` class (`GoodsInventoryServiceRoutingHealthCheck`) registered via JTier. Heartbeat liveness is configured via `jtier.health.heartbeatPath` pointing to `./heartbeat.txt`. No active health probe against GIS is implemented in the application; connectivity failures surface at request time as `UNABLE_TO_REACH_GIS` error responses.
