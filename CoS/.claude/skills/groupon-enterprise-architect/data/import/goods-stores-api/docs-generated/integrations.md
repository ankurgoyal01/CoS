---
service: "goods-stores-api"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 1
internal_count: 9
---

# Integrations

## Overview

Goods Stores API has one external integration (Avalara Tax API) and nine internal Continuum service dependencies. All internal integrations use HTTP/JSON, with the majority accessed via `schema_driven_client` typed adapters. The service is a significant integration hub: deal catalog synchronization, pricing, taxonomy, orders, inventory, user/token resolution, geo-place metadata, deal management, and tax compliance are all delegated to peer Continuum services.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Avalara Tax API | rest | Validates and syncs merchant tax compliance details | yes | `continuumAvalaraService` |

### Avalara Tax API Detail

- **Protocol**: HTTP/JSON (REST)
- **Base URL / SDK**: Configured via environment variable; called through `continuumGoodsStoresApi_integrationClients`
- **Auth**: Avalara API credentials configured as secrets
- **Purpose**: Validates merchant Avalara tax account details and syncs tax configuration when merchants are created or updated
- **Failure mode**: Merchant tax detail operations fail; API returns error to caller; no automatic retry identified in inventory
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog | rest (SchemaDrivenClient) | Fetches and updates deal/product details; syncs deal nodes and variants | `continuumDealCatalogService` |
| Pricing | rest (SchemaDrivenClient) | Retrieves current pricing for goods options during API and worker processing | `continuumPricingService` |
| Taxonomy | rest (HTTP/RestClient) | Retrieves category trees and attributes for product classification | `continuumTaxonomyService` |
| Orders | rest (SchemaDrivenClient) | Manages merchant Avalara tax accounts via Orders service integration | `continuumOrdersService` |
| Deal Management API | rest (HTTP/JSON) | Creates, updates, and publishes deals and inventory products | `continuumDealManagementApi` |
| Bhuvan | rest (HTTP/JSON) | Resolves geoplaces and divisions metadata for merchant/product location data | `continuumBhuvanService` |
| M3 Places | rest (HTTP/JSON) | Reads and writes merchant place details | `continuumM3PlacesService` |
| Goods Inventory | rest (HTTP/JSON) | Reads and updates inventory product availability; publishes inventory state updates from workers | `continuumGoodsInventoryService` |
| Users | rest (HTTP/JSON) | Fetches user account data and validates GPAPI tokens for authorization | `continuumUsersService` |
| Message Bus | JMS/STOMP | Consumes marketData and pricing change topics | `messageBus` |

### Deal Catalog Detail

- **Protocol**: HTTP/JSON via SchemaDrivenClient
- **Auth**: Internal service credentials
- **Purpose**: Synchronizes goods product data with the Deal Catalog; fetches deal/product details for enrichment; syncs deal nodes and variants via workers
- **Failure mode**: Product/deal sync operations fail; workers may retry based on Resque retry configuration
- **Circuit breaker**: No evidence found

### Pricing Detail

- **Protocol**: HTTP/JSON via SchemaDrivenClient
- **Auth**: Internal service credentials
- **Purpose**: Retrieves current pricing for goods options to enrich product data during API responses and worker post-processing
- **Failure mode**: Pricing enrichment fails gracefully; degraded product data returned
- **Circuit breaker**: No evidence found

### Taxonomy Detail

- **Protocol**: HTTP/JSON via RestClient
- **Auth**: Internal service credentials
- **Purpose**: Retrieves category trees and attribute definitions to support product taxonomy assignment and display
- **Failure mode**: Taxonomy data unavailable; API returns error or cached/stale taxonomy
- **Circuit breaker**: No evidence found

### Orders Detail

- **Protocol**: HTTP/JSON via SchemaDrivenClient
- **Auth**: Internal service credentials
- **Purpose**: Used specifically for managing merchant Avalara tax accounts through the Orders service
- **Failure mode**: Merchant tax account operations fail
- **Circuit breaker**: No evidence found

### Deal Management API Detail

- **Protocol**: HTTP/JSON
- **Auth**: Internal service credentials
- **Purpose**: Creates, updates, and publishes deals and inventory products as part of the goods-to-deal lifecycle
- **Failure mode**: Deal publishing operations fail; workers may retry
- **Circuit breaker**: No evidence found

### Goods Inventory Detail

- **Protocol**: HTTP/JSON
- **Auth**: Internal service credentials
- **Purpose**: Reads inventory product availability for enrichment; workers publish inventory state updates after domain changes
- **Failure mode**: Inventory reads return error; inventory updates queued for retry
- **Circuit breaker**: No evidence found

### Users Detail

- **Protocol**: HTTP/JSON
- **Auth**: Internal service credentials
- **Purpose**: Fetches user account data and performs GPAPI token validation to authorize incoming API requests
- **Failure mode**: Authorization fails; requests rejected with 401/403
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include GPAPI clients and merchant-facing tooling.

## Dependency Health

> Specific health check, retry, or circuit breaker patterns for outbound dependencies are not discoverable from the repository inventory. Operational procedures to be defined by service owner. All internal calls use HTTP/JSON; `schema_driven_client` provides typed request/response handling but no circuit breaker configuration was identified.
