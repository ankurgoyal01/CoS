---
service: "dynamic_pricing"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 0
internal_count: 4
---

# Integrations

## Overview

The Pricing Service has four internal Continuum dependencies. It makes synchronous outbound HTTP calls to the Voucher Inventory Service and Deal Catalog Service for validation data during price operations. It communicates with the MBus Broker both as a publisher (outbound price events) and as a consumer (inbound inventory events). All inbound API traffic arrives through the API proxy and is routed by the Dynamic Pricing NGINX layer.

## External Dependencies

> Not applicable. The Pricing Service has no external (outside Continuum) dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Voucher Inventory Service | HTTP | Fetches product and unit inventory details for validation during price creation | `continuumVoucherInventoryService` |
| Deal Catalog Service | HTTP | Retrieves deal metadata to validate program price requests | `continuumDealCatalogService` |
| MBus Broker | JMS | Publishes price change events; receives VIS inventory update events | `continuumMbusBroker` |
| Logging Stack | Filebeat/HTTP | Receives NGINX access/error logs from `continuumDynamicPricingNginx` | `loggingStack` |

### Voucher Inventory Service Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Internal Continuum service; accessed via `continuumPricingService_visHttpClient` (FederatedInventoryService/VISClient, Apache HttpClient)
- **Auth**: Internal Continuum service-to-service auth
- **Purpose**: Provides product capacity and inventory unit details required during program price bulk creation validation and retail price updates
- **Failure mode**: Program price creation and retail price updates that require inventory validation will fail if VIS is unavailable
- **Circuit breaker**: No evidence found

### Deal Catalog Service Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Internal Continuum service; accessed via `continuumPricingService_dealCatalogClient` (DealCatalogClient)
- **Auth**: Internal Continuum service-to-service auth
- **Purpose**: Supplies deal metadata (titles, options, option group structure) needed to validate program price creation requests
- **Failure mode**: Bulk program price creation requests requiring deal metadata will fail if Deal Catalog is unavailable
- **Circuit breaker**: No evidence found

### MBus Broker Detail

- **Protocol**: JMS (HornetQ/ActiveMQ)
- **Base URL / SDK**: `continuumMbusBroker` container; accessed via `continuumPricingService_mbusPublishers` and `continuumPricingService_mbusConsumers`
- **Auth**: Internal JMS broker connection
- **Purpose**: Asynchronous event distribution — publishes `dynamic.pricing.update`, `retail_price_events`, `program_price_events`, `price_rule.update`; receives `InventoryUnits.Updated.Vis`, `InventoryProducts.UpdatedSnapshot.Vis`
- **Failure mode**: Event publication failures are local to the price update workflow; consumed events will queue until the service reconnects
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. The Pricing Service is called by internal Continuum services and APIs via `apiProxy` routing through `continuumDynamicPricingNginx`.

## Dependency Health

> Operational procedures to be defined by service owner. No circuit breaker or health check patterns for outbound HTTP dependencies are documented in the available architecture inventory. The NGINX `/heartbeat.txt` endpoint provides liveness/readiness signaling for the service itself.
