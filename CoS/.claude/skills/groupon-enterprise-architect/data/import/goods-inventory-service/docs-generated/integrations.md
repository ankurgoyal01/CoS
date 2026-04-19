---
service: "goods-inventory-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 8
internal_count: 3
---

# Integrations

## Overview

Goods Inventory Service integrates with 8 external HTTP services and 3 internal infrastructure components (PostgreSQL, Redis, MessageBus). The external integrations span upstream inventory sources, downstream fulfillment systems, platform APIs, and auxiliary services for pricing, currency, and delivery estimation. All external service calls are made via dedicated HTTP clients built on Play WS.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Goods Inventory Management Service | REST | Synchronize inventory with upstream IMS | yes | `goodsInventoryManagementService` |
| Goods Stores Service | REST | Fetch gateway inventory and store info for routing and add-back | yes | `goodsStoresService` |
| GPAPI Service | REST | Additional product and deal metadata | no | `gpapiService` |
| SRS Outbound Controller | REST | Cancel or manage exported units in shipping | yes | `srsOutboundController` |
| ORC Service | REST | Order routing and fulfillment coordination | yes | `orcService` |
| Item Master Service | REST | Static item/SKU information synchronization | no | `itemMasterService` |
| Currency Conversion Service | REST | Currency conversion rates for pricing flows | no | `currencyConversionService` |
| Delivery Estimator Service | REST | Delivery and shipping estimates | no | `deliveryEstimatorService` |

### Goods Inventory Management Service Detail

- **Protocol**: HTTP/JSON via IMSClient
- **Auth**: Internal service authentication
- **Purpose**: Primary upstream source for warehouse inventory data. GIS synchronizes product and unit data from IMS to maintain local inventory state.
- **Failure mode**: IMS unavailability prevents inventory sync; GIS continues serving from local DB state but may serve stale availability data
- **Circuit breaker**: Expected via Play WS client configuration

### Goods Stores Service Detail

- **Protocol**: HTTP/JSON via GoodsStoresClient
- **Auth**: Internal service authentication
- **Purpose**: Provides gateway inventory and store information used for routing decisions and add-back logic during reverse fulfillment (returning cancelled units to available inventory)
- **Failure mode**: Degraded add-back logic and routing decisions; cancellations may proceed without add-back
- **Circuit breaker**: Expected via Play WS client configuration

### SRS Outbound Controller Detail

- **Protocol**: HTTP/JSON via SRSClient
- **Auth**: Internal service authentication
- **Purpose**: Manages exported inventory units in the outbound shipping pipeline. GIS calls SRS to cancel exported units during reverse fulfillment.
- **Failure mode**: Reverse fulfillment for exported units may fail or be delayed; units remain in exported state
- **Circuit breaker**: Expected via Play WS client configuration

### ORC Service Detail

- **Protocol**: HTTP/JSON via OrcClient
- **Auth**: Internal service authentication
- **Purpose**: Order routing and fulfillment coordination. GIS interacts with ORC as part of the order fulfillment pipeline.
- **Failure mode**: Order fulfillment coordination may be delayed; GIS retries or queues pending operations
- **Circuit breaker**: Expected via Play WS client configuration

### GPAPI Service Detail

- **Protocol**: HTTP/JSON via GpapiClient
- **Auth**: Internal service authentication
- **Purpose**: Retrieves additional product and deal metadata from the Groupon platform API to enrich inventory product data.
- **Failure mode**: Products may be served without supplemental metadata; non-critical enrichment
- **Circuit breaker**: Expected via Play WS client configuration

### Item Master Service Detail

- **Protocol**: HTTP/JSON via ItemMasterClient
- **Auth**: Internal service authentication
- **Purpose**: Synchronizes static item and SKU information from the GFI/Item Master system to maintain product reference data.
- **Failure mode**: Item data may become stale; sync retries on next scheduled run
- **Circuit breaker**: Expected via Play WS client configuration

### Currency Conversion Service Detail

- **Protocol**: HTTP/JSON
- **Auth**: Internal service authentication
- **Purpose**: Provides currency conversion rates used in pricing and inventory flows for multi-currency support.
- **Failure mode**: Pricing flows may use cached rates or fail for cross-currency operations
- **Circuit breaker**: Expected via Play WS client configuration

### Delivery Estimator Service Detail

- **Protocol**: HTTP/JSON
- **Auth**: Internal service authentication
- **Purpose**: Provides delivery and shipping time estimates for inventory products based on origin, destination, and carrier.
- **Failure mode**: Delivery estimates unavailable; products may be served without estimated delivery windows
- **Circuit breaker**: Expected via Play WS client configuration

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Goods Inventory DB | JDBI/PostgreSQL | Primary relational data store | `continuumGoodsInventoryDb` |
| Goods Inventory Redis Cache | Redis | Caching layer for product views and pricing | `continuumGoodsInventoryRedis` |
| Goods Inventory Message Bus | Groupon MessageBus | Async event publishing and consumption | `continuumGoodsInventoryMessageBus` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Checkout services | REST | Query product availability, create/manage reservations |
| GPAPI / platform APIs | REST | Retrieve inventory product data for consumer-facing experiences |
| Operational / admin tools | REST | Manage vendor tax, postal codes, message rules |

> Upstream consumers are tracked in the central architecture model. The list above reflects known primary consumers based on the API surface.

## Dependency Health

The service relies on Play WS HTTP clients for all external calls, which support configurable timeouts and connection pooling. Individual client configurations (timeout, retry, circuit breaker) are managed through Play application configuration files (`conf/*.conf`). Redis and PostgreSQL connections use pooled clients with health-check capabilities. The MessageBus SDK provides built-in retry and error handling for message publishing and consumption.
