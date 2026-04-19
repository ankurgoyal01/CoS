---
service: "api-lazlo-sox"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 16
---

# Integrations

## Overview

API Lazlo is an aggregation gateway with a large internal dependency footprint. It integrates with 16+ downstream Groupon domain microservices via synchronous HTTP/JSON calls through typed Lazlo client modules. It has no direct external (third-party) dependencies -- all external integrations are mediated by the downstream domain services.

The downstream service clients (`continuumApiLazloService_downstreamServiceClients` and `continuumApiLazloSoxService_downstreamServiceClients`) encapsulate all outbound HTTP communication and provide typed request/response handling, connection pooling, and error mapping.

## External Dependencies

API Lazlo does not directly integrate with external third-party systems. All external dependencies (payment processors, email providers, geo APIs, etc.) are mediated by the downstream domain services it aggregates.

## Internal Dependencies

### API Lazlo Service (`continuumApiLazloService`)

| Service | Protocol | Purpose | Client Component |
|---------|----------|---------|-----------------|
| Users Service | HTTP/JSON | User profile, account management, authentication | `continuumApiLazloService_downstreamServiceClients` |
| Consumer Service | HTTP/JSON | Consumer identity and preferences | `continuumApiLazloService_downstreamServiceClients` |
| Program Enrollment Service | HTTP/JSON | Loyalty and program enrollment status | `continuumApiLazloService_downstreamServiceClients` |
| Subscriptions Service | HTTP/JSON | User subscription management | `continuumApiLazloService_downstreamServiceClients` |
| Deal Service | HTTP/JSON | Deal details, deal discovery, merchandising | `continuumApiLazloService_downstreamServiceClients` |
| Catalog Service | HTTP/JSON | Product catalog and listing data | `continuumApiLazloService_downstreamServiceClients` |
| Inventory Service | HTTP/JSON | Deal and product inventory availability | `continuumApiLazloService_downstreamServiceClients` |
| Geo Service | HTTP/JSON | Geographic data, divisions, markets | `continuumApiLazloService_downstreamServiceClients` |
| Taxonomy Service | HTTP/JSON | Category taxonomy trees and mappings | `continuumApiLazloService_downstreamServiceClients` |
| Relevance Service | HTTP/JSON | Personalization and recommendation scoring | `continuumApiLazloService_downstreamServiceClients` |
| Content Service | HTTP/JSON | Content management and editorial content | `continuumApiLazloService_downstreamServiceClients` |
| Orders Service | HTTP/JSON | Order creation, retrieval, and management | `continuumApiLazloService_downstreamServiceClients` |
| Cart Service | HTTP/JSON | Shopping cart state management | `continuumApiLazloService_downstreamServiceClients` |
| Payment Service | HTTP/JSON | Payment processing and payment method management | `continuumApiLazloService_downstreamServiceClients` |
| Bucks Service | HTTP/JSON | Groupon Bucks / credits management | `continuumApiLazloService_downstreamServiceClients` |
| Voucher Service | HTTP/JSON | Voucher generation and redemption | `continuumApiLazloService_downstreamServiceClients` |
| Messaging Service | HTTP/JSON | Notification and messaging delivery | `continuumApiLazloService_downstreamServiceClients` |

### API Lazlo SOX Service (`continuumApiLazloSoxService`)

| Service | Protocol | Purpose | Client Component |
|---------|----------|---------|-----------------|
| Users Service | HTTP/JSON | SOX-regulated user identity and account flows | `continuumApiLazloSoxService_downstreamServiceClients` |
| Orders Service | HTTP/JSON | SOX-regulated order and booking operations | `continuumApiLazloSoxService_downstreamServiceClients` |
| Inventory Service | HTTP/JSON | Partner inventory for SOX-regulated views | `continuumApiLazloSoxService_downstreamServiceClients` |
| Partners Service | HTTP/JSON | SOX partner data and booking configuration | `continuumApiLazloSoxService_downstreamServiceClients` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon iOS App | HTTP/JSON (REST) | Primary mobile client consuming the /api/mobile/ endpoints |
| Groupon Android App | HTTP/JSON (REST) | Primary mobile client consuming the /api/mobile/ endpoints |
| Groupon Web Client | HTTP/JSON (REST) | Web browser client consuming the /api/mobile/ endpoints |
| MBNXT PWA | HTTP/JSON (REST) | Next-gen progressive web app consuming the /api/mobile/ endpoints |

> Upstream consumers are also tracked in the central architecture model under `continuumSystem`.

## Dependency Health

### Client-Side Patterns

The Lazlo client-core framework provides built-in patterns for dependency health:

- **Connection pooling**: HTTP connections to downstream services are pooled and managed by the Lazlo client framework
- **Timeouts**: Per-client configurable connect and read timeouts
- **Retry logic**: Configurable retry policies per downstream client
- **Error mapping**: Typed error handling that maps downstream HTTP errors to appropriate API Lazlo response codes
- **Metrics**: Per-client metrics (latency, error rate, throughput) via the metrics-vertx integration

### Health Check Endpoints

- `/healthcheck` -- Verifies the service is running and accepting connections
- `/readiness` -- Verifies downstream dependencies are reachable and the service is ready to serve traffic
- `/warmup` -- Pre-populates caches and establishes connections to downstream services before accepting production traffic
