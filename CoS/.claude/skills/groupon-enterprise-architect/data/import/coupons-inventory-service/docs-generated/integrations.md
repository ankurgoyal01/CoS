---
service: "coupons-inventory-service"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 1
---

# Integrations

## Overview

Coupons Inventory Service integrates with two external services via HTTP/JSON (Deal Catalog Service and VoucherCloud) and one internal messaging system (IS Core Message Bus). The external integrations are called via OkHttp clients. The message bus integration uses the Groupon Mbus library for both publishing and consuming events.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Deal Catalog Service | REST (HTTP/JSON) | Resolves deal identifiers for newly created inventory products | Yes | `continuumCouponsInventoryService_dealCatalogClient` |
| VoucherCloud | REST (HTTP/JSON) | Fetches unique redemption codes for reservations | Yes | `continuumCouponsInventoryService_voucherCloudClient` |

### Deal Catalog Service Detail

- **Protocol**: HTTP/JSON (REST)
- **Base URL / SDK**: OkHttp client (base URL configured externally)
- **Auth**: Internal service-to-service authentication (inferred from Continuum platform conventions)
- **Purpose**: The Inventory Product Creation Processor calls the Deal Catalog Service to resolve deal identifiers for newly created inventory products. These deal-ids are then persisted to the database and cached in Redis.
- **Failure mode**: If the Deal Catalog Service is unavailable, the Inventory Product Creation Processor cannot resolve deal-ids for new products. Products will be created but deal-id enrichment will be delayed until the service recovers and messages are reprocessed.
- **Circuit breaker**: No evidence found in architecture DSL; confirm with service owner.
- **Architecture ref**: `continuumCouponsInventoryService_dealCatalogClient`

### VoucherCloud Detail

- **Protocol**: HTTP/JSON (REST)
- **Base URL / SDK**: OkHttp client (base URL configured externally)
- **Auth**: External API authentication (mechanism not specified in architecture DSL)
- **Purpose**: The Reservation Domain calls VoucherCloud to fetch unique redemption codes when creating reservations that require them.
- **Failure mode**: If VoucherCloud is unavailable, reservation creation requiring unique redemption codes will fail. Reservations not requiring redemption codes are unaffected.
- **Circuit breaker**: No evidence found in architecture DSL; confirm with service owner.
- **Architecture ref**: `continuumCouponsInventoryService_voucherCloudClient`

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| IS Core Message Bus | Mbus | Publishes inventory product creation events; consumes IS Core orders and GDPR messages | `continuumCouponsInventoryMessageBus` |

### IS Core Message Bus Detail

- **Protocol**: Mbus (Groupon internal message bus)
- **Purpose**: The service publishes `inventoryProduct.create` events via the Message Bus Publisher when new products are created. It consumes those same events via the Inventory Product Creation Processor for deal-id resolution. It also consumes IS Core order events and GDPR compliance events via IS Core Bus Consumers.
- **Failure mode**: If the message bus is unavailable, product creation events cannot be published, and deal-id resolution will be delayed. IS Core order and GDPR message processing will also be paused.
- **Architecture ref**: `continuumCouponsInventoryMessageBus`

## Consumed By

> Upstream consumers are tracked in the central architecture model. The service exposes REST APIs for inventory product, unit, reservation, click, and availability operations consumed by internal Continuum platform services.

## Dependency Health

- **Database**: Health Checks & Metrics component (`continuumCouponsInventoryService_healthChecks`) performs database connectivity checks against `continuumCouponsInventoryService_jdbiInfrastructure` via Dropwizard health check queries.
- **Redis**: Connection health is managed by the Jedis client abstraction (`continuumCouponsInventoryService_redisClient`).
- **External services (Deal Catalog, VoucherCloud)**: No evidence found of dedicated health checks or circuit breaker patterns for external HTTP dependencies. Connection failures are expected to be handled via standard OkHttp timeout and retry behavior.
- **Message Bus**: Managed by Dropwizard's ManagedReader lifecycle, which handles connection management and reconnection.
