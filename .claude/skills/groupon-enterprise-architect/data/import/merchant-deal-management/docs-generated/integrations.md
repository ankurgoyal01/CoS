---
service: "merchant-deal-management"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 11
---

# Integrations

## Overview

The Merchant Deal Management service maintains one external dependency (Salesforce) and eleven internal Continuum service dependencies. All integrations use HTTP/JSON via Faraday and ServiceDiscoveryClient in the `dmapiRemoteClientGateway` and `dmapiWorkerRemoteClientGateway` components. The API container handles synchronous calls to most dependencies; the worker container handles asynchronous calls to the deal catalog service and Salesforce. Both containers emit structured logs and metrics to shared platform observability infrastructure.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS/REST | Reads and writes deal/merchant data; asynchronous updates processed by worker | yes | `salesForce` |

### Salesforce Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Not resolvable from available inventory
- **Auth**: Not resolvable from available inventory
- **Purpose**: Bidirectional synchronization of deal and merchant records between Continuum and Salesforce CRM; synchronous calls from the API and asynchronous processing from the worker
- **Failure mode**: Not specified; Salesforce call failures may leave write requests in a pending state pending retry by the worker
- **Circuit breaker**: Not specified in available inventory

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | HTTP/JSON | Reads and updates deal catalog entities (sync); processes asynchronous deal catalog updates (worker) | `continuumDealCatalogService` |
| Orders Service | HTTP/JSON | Reads order-facing mapping data required during deal write flows | `continuumOrdersService` |
| Pricing Service | HTTP/JSON | Validates and updates pricing payloads for deals being written | `continuumPricingService` |
| Taxonomy Service | HTTP/JSON | Resolves taxonomy metadata for deals during write orchestration | `continuumTaxonomyService` |
| Geo Service | HTTP/JSON | Resolves division and geolocation data for deal geographic targeting | `continuumGeoService` |
| M3 Merchant Service | HTTP/JSON | Reads and writes merchant profiles and writeups associated with deals | `continuumM3MerchantService` |
| M3 Places Service | HTTP/JSON | Reads and writes merchant place records linked to deals | `continuumM3PlacesService` |
| Voucher Inventory Service | HTTP/JSON | Synchronizes voucher inventory products during deal writes | `continuumVoucherInventoryService` |
| Third-Party Inventory Service | HTTP/JSON | Synchronizes third-party inventory products during deal writes | `continuumThirdPartyInventoryService` |
| Goods Inventory Service | HTTP/JSON | Synchronizes goods inventory products during deal writes | `continuumGoodsInventoryService` |
| Coupons Inventory Service | HTTP/JSON | Synchronizes coupons inventory products during deal writes | `continuumCouponsInventoryService` |
| CLO Inventory Service | HTTP/JSON | Synchronizes CLO (card-linked offer) inventory products during deal writes | `continuumCloInventoryService` |
| Appointments Engine | HTTP/JSON | Sends appointment-related updates when deals include appointment capabilities | `continuumAppointmentsEngine` |
| Contract Data Service | HTTP/JSON | Deal contract data reads/writes (relationship tracked in central model) | `continuumContractDataService` |
| Logging Stack | Structured Logs | Receives application and worker telemetry logs from both containers | `loggingStack` |
| Metrics Stack | Metrics | Receives runtime and request metrics from both containers | `metricsStack` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The service is consumed by internal Groupon tools and merchant-facing portals that submit deal write requests via HTTP.

## Dependency Health

All downstream Continuum service calls use Faraday HTTP clients via ServiceDiscoveryClient for routing. Specific health check, retry, or circuit breaker configuration for individual dependencies is not resolvable from the available inventory. The service emits metrics to `metricsStack` and logs to `loggingStack` for observability of dependency call outcomes.
