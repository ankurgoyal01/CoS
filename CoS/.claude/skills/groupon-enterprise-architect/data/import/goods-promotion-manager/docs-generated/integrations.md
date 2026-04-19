---
service: "goods-promotion-manager"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 2
---

# Integrations

## Overview

Goods Promotion Manager has two outbound synchronous REST integrations to other internal Groupon services. Both are configured as Retrofit2 HTTP clients via the JTier `jtier-retrofit` bundle. There are no external third-party integrations and no message-bus dependencies.

## External Dependencies

> No evidence found in codebase. No external third-party systems are called.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Management API | HTTPS/REST | Fetches full deal details (inventory products, pricing) during the Import Product Job | `continuumDealManagementApi` |
| Core Pricing Service | HTTPS/REST | Fetches established prices per inventory product and promotion start date during the Update Established Price Job | `corePricingServiceSystem` |

### Deal Management API (`continuumDealManagementApi`) Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Configured via `dealManagementApiClient` (Retrofit2 `RetrofitConfiguration` in service YAML config)
- **Auth**: JTier client-auth (inherited from `jtier-retrofit` configuration)
- **Endpoint called**: `GET /v2/deals/{id}?expand[0]=full` — retrieves deal with full inventory product and pricing expansion
- **Purpose**: Imports deal and inventory product reference data (deal UUID, permalink, purchasability region, unit prices, inventory product UUIDs) into the local `deal` and `inventory_product` tables so that eligibility and CSV export can operate without a live call per request
- **Failure mode**: If the Deal Management API is unavailable during an Import Product Job run, the job logs a warning and the affected deals will not have current pricing data. The service continues to serve requests using previously imported data.
- **Circuit breaker**: No evidence found in codebase.

### Core Pricing Service (`corePricingServiceSystem`) Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Configured via `corePricingApiClient` (Retrofit2 `RetrofitConfiguration` in service YAML config)
- **Auth**: JTier client-auth (inherited from `jtier-retrofit` configuration)
- **Endpoint called**: `GET /pricing_service/v2.0/product/{inventoryProductId}/established_price/{at}` — retrieves the established (reference) price for an inventory product at a given promotion start timestamp
- **Purpose**: Populates established price fields on `promotion_inventory_product` records during the Update Established Price Job, enabling accurate ILS pricing in CSV exports
- **Failure mode**: If the Core Pricing Service is unavailable, the Update Established Price Job cannot populate prices. Existing prices remain unchanged; CSV exports may contain stale pricing data.
- **Circuit breaker**: No evidence found in codebase.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Internal clients (merchandise and pricing teams) access the service via authenticated REST calls, typically through internal tooling. The Optimus job `ILS_marketing_grid_update_ILS_new_disc` is a known caller per service README.

## Dependency Health

- Client connectivity for both `dealManagementApiClient` and `corePricingApiClient` is managed through JTier's Retrofit bundle with configurable connection/read timeouts defined in the service YAML config files.
- No explicit circuit breaker or retry configuration is evidenced beyond JTier defaults.
- Health of downstream services is not surfaced through the service's own `/status.json` endpoint.
