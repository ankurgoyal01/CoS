---
service: "Deal-Estate"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 1
internal_count: 9
---

# Integrations

## Overview

Deal-Estate has one external dependency (Salesforce) and nine active internal Continuum service dependencies. All outbound HTTP calls use the `service-client` gem (v2.0.16) or `httparty` (v1.3.1). An additional five services are referenced in the architecture model as stubs-only (not in the federated model), meaning those relationships exist in the running system but their targets are not modelled centrally.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | REST / SDK | Syncs merchant accounts, opportunities, pricing, planning objects, and options into Deal-Estate | yes | `salesForce` |

### Salesforce Detail

- **Protocol**: REST / SDK (httparty-based outbound calls and message bus event consumption)
- **Base URL / SDK**: Salesforce integration via `salesForce` stub — exact base URL managed by environment config
- **Auth**: Managed via environment secrets (OAuth credentials or API token)
- **Purpose**: Salesforce is the system of record for merchant accounts, deal opportunities, planning objects, prices, and options. Deal-Estate consumes Salesforce events to keep deal records current and may make synchronous calls for on-demand data retrieval.
- **Failure mode**: If Salesforce is unavailable, async event processing will queue in Resque and retry; synchronous calls may surface errors to the caller
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog | REST (service-client) | Reads deal and product data; consumes deal lifecycle events | `continuumDealCatalogService` |
| Deal Management API | REST (service-client) | Reads and writes deal management records | `continuumDealManagementApi` |
| Taxonomy Service | REST (service-client) | Reads taxonomy/category data for deal classification | `continuumTaxonomyService` |
| Voucher Inventory Service | REST (service-client) | Manages and syncs voucher inventory for deals | `continuumVoucherInventoryService` |
| Custom Fields Service | REST (service-client) | Reads and writes deal custom fields | `continuumCustomFieldsService` |
| Geo Places Service | REST (service-client) | Geo-places lookups for deal location data | `continuumGeoPlacesService` |
| Orders Service | REST (service-client) | Reads order data associated with deals | `continuumOrdersService` |
| Groupon API | REST (service-client) | Reads internal Groupon platform data | `continuumGrouponApi` |
| Inventory Service | REST (service-client) | Manages deal inventory (referenced in summary; stub not in federated model) | — |

### Stub-Only Dependencies (not in federated model)

The following services are referenced in the codebase but their architecture models are not in the central federated model:

| Service | Purpose |
|---------|---------|
| `dealBookService` | Reads and writes deal book data |
| `draftService` | Reads and writes deal drafts |
| `grouponImagesService` | Uploads and reads deal images |
| `m3Service` | Syncs merchant location data |
| `geodetailService` | Geolocation detail lookups |
| `rocketmanService` | Feature flagging and experiments |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- All synchronous dependencies are called via `service-client` which provides standard retry and timeout configuration.
- Async dependencies (Salesforce events, Deal Catalog events) are processed by `continuumDealEstateWorker` with Resque's built-in retry mechanism; failed jobs are retained in the Resque failed queue and visible in `continuumDealEstateResqueWeb`.
- No explicit circuit breaker pattern is evidenced in the federated model; consult service owner for runtime configuration.
