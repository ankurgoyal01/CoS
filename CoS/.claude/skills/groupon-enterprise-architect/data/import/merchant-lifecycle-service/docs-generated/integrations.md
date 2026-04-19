---
service: "merchant-lifecycle-service"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 12
---

# Integrations

## Overview

Merchant Lifecycle Service has a broad integration footprint: one external dependency (FIS, via dedicated client library) and twelve internal Continuum service dependencies accessed over HTTP. `continuumMlsRinService` calls most of them synchronously during request handling. `continuumMlsSentinelService` calls a subset during Kafka-driven index maintenance flows. All HTTP clients are managed via Retrofit and the JTier retrofit bundle.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| FIS (TPIS / Goods / Voucher) | sdk | Federated Inventory Service client for inventory product and voucher queries | yes | `continuumInventoryService` (via fis-client 0.6.6) |

### FIS (TPIS / Goods / Voucher) Detail

- **Protocol**: FIS client SDK (fis-client 0.6.6)
- **Base URL / SDK**: `fis-client` library version 0.6.6 — manages TPIS, Goods, and Voucher sub-clients
- **Auth**: Managed by FIS client / JTier auth bundle
- **Purpose**: Fetches inventory product payloads, voucher inventory state, and unit availability during unit search aggregation and inventory sync flows
- **Failure mode**: Unit search and inventory index update flows degrade; affected fields may be absent from search results
- **Circuit breaker**: Not evidenced in architecture inventory; to be confirmed by service owner

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | HTTP (REST) | Fetches deal catalog, templates, and reacts to catalog events | `continuumDealCatalogService` |
| Marketing Analytics / Deal Service | HTTP (REST) | Queries marketing analytics and deal-index data | `continuumMarketingDealService` |
| Voucher Inventory Service (VIS) | HTTP (REST) | Queries voucher inventory and unit data | `continuumVoucherInventoryService` |
| GLive Inventory Service | HTTP (REST) | Queries GLive inventory data | `continuumGLiveInventoryService` |
| Bhuvan (Geo / Places) | HTTP (REST) | Resolves geo places and divisions for unit search enrichment | `continuumBhuvanService` |
| M3 Merchant Service | HTTP (REST) | Fetches merchant account details | `continuumM3MerchantService` |
| UGC Service | HTTP (REST) | Fetches user-generated content summaries | `continuumUgcService` |
| Orders Service | HTTP (REST) | Fetches order and billing records for CLO and insights flows | `continuumOrdersService` |
| Pricing Service | HTTP (REST) | Resolves pricing context and ILS programs | `continuumPricingService` |
| Merchant Advisor Service | HTTP (REST) | Fetches merchant advisor metrics for insights aggregation | `merchantAdvisorService` |
| Continuum Inventory Service (FIS-backed) | HTTP (REST) | Calls federated FIS-backed inventory APIs for unit search and backfill flows | `continuumInventoryService` |
| MBus / Kafka | MBus/Kafka | Consumes deal catalog and inventory update events; publishes DealSnapshotUpdated and InventoryProductIndexed | `messageBus` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- All HTTP dependencies use Retrofit clients configured via the JTier retrofit bundle, which provides managed connection pooling and timeouts.
- `continuumMlsSentinelService` includes a DLQ flow handler (`sentinelProcessingFlows`) to handle failures during Kafka-driven index maintenance.
- Circuit breaker and retry configuration details are not evidenced in the architecture inventory; to be confirmed by service owner.
