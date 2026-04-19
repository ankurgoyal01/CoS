---
service: "deal-management-api"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 1
internal_count: 10
---

# Integrations

## Overview

DMAPI integrates with one external system (Salesforce) and ten internal Continuum services. All integrations use REST over HTTPS. Internal services are located via the `service-discovery-client` library. The API container issues synchronous calls during request handling; the Worker container handles async calls to Salesforce and Deal Catalog Service via Resque jobs. HTTP clients are Typhoeus (MRI runtime) and Manticore (JRuby runtime).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | REST/HTTPS | CRM sync of deal and merchant records | yes | `salesForce` |

### Salesforce Detail

- **Protocol**: REST/HTTPS
- **Base URL / SDK**: Configured via environment/service discovery (not hardcoded in inventory)
- **Auth**: OAuth or API token (configured via secrets)
- **Purpose**: Synchronizes deal and merchant data to Groupon's Salesforce CRM. Both the API (synchronous path) and the Worker (asynchronous path) push updates.
- **Failure mode**: Sync failures in the API path surface as errors to the caller; async Worker failures are retried via Resque retry mechanics.
- **Circuit breaker**: No evidence found in inventory

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | REST/HTTPS | Publishes deal catalog data on create/update/publish | `continuumDealCatalogService` |
| Orders Service | REST/HTTPS | Reads order data associated with deals | `continuumOrdersService` |
| Pricing Service | REST/HTTPS | Fetches pricing data for deal inventory configuration | `continuumPricingService` |
| Taxonomy Service | REST/HTTPS | Reads taxonomy classification for deal categorization | `continuumTaxonomyService` |
| Contract Data Service | REST/HTTPS | Fetches and manages contract and contract party data | `continuumContractDataService` |
| Voucher Inventory Service | REST/HTTPS | Inventory lookups for voucher-type deals | `continuumVoucherInventoryService` |
| Coupons Inventory Service | REST/HTTPS | Inventory lookups for coupon-type deals | `continuumCouponsInventoryService` |
| Goods Inventory Service | REST/HTTPS | Inventory lookups for goods-type deals | `continuumGoodsInventoryService` |
| Third-Party Inventory Service | REST/HTTPS | Inventory lookups for third-party deals | `continuumThirdPartyInventoryService` |
| CLO Inventory Service | REST/HTTPS | Inventory lookups for CLO (Card-Linked Offer) deals | `continuumCloInventoryService` |

> Note: `m3` (merchant/places data service) is referenced in the architecture stubs as a dependency but is marked `stub_only` — the integration exists in code but the target service is not yet in the federated architecture model.

### Deal Catalog Service (`continuumDealCatalogService`) Detail

- **Protocol**: REST/HTTPS
- **Purpose**: Receives deal data on publish, unpublish, and significant updates so the catalog stays current. Both synchronous (API) and asynchronous (Worker) paths are used.
- **Failure mode**: Async failures retried via Resque; sync failures surface to caller
- **Circuit breaker**: No evidence found in inventory

### Inventory Services Detail

The five inventory services (`continuumVoucherInventoryService`, `continuumCouponsInventoryService`, `continuumGoodsInventoryService`, `continuumThirdPartyInventoryService`, `continuumCloInventoryService`) are called by the API during deal configuration to look up available inventory products and validate inventory constraints per deal type.

- **Protocol**: REST/HTTPS via `remoteClients` component
- **Failure mode**: Returns error to caller if inventory lookup fails; no fallback cached inventory identified
- **Circuit breaker**: No evidence found in inventory

## Consumed By

> Upstream consumers are tracked in the central architecture model. Internal deal setup tooling, merchant portals, and campaign management systems are known consumers of DMAPI's REST API.

## Dependency Health

- Service discovery is managed via `service-discovery-client 2.2.1`, which handles endpoint resolution for all internal services.
- HTTP calls use Typhoeus (MRI) or Manticore (JRuby) with configurable timeouts.
- No explicit circuit breaker library was identified in the inventory. Retry behavior for async Worker calls is provided by Resque's built-in retry and failure queue mechanisms.
