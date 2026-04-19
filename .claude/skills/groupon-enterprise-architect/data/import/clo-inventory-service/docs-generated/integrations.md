---
service: "clo-inventory-service"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 5
internal_count: 2
---

# Integrations

## Overview

CLO Inventory Service integrates with five external HTTP/JSON services and two internal data stores. All external service communication uses HTTP/JSON via Retrofit-based clients, following JTIER service-to-service conventions. The service has a fan-out pattern: the External Service Integrations component encapsulates all downstream HTTP clients, providing a clean boundary between domain logic and external calls.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| CLO Core Service | REST (HTTP/JSON) | Creates/updates CLO offers, claims, and manages card enrollments | Yes | `continuumCloCoreService` |
| CLO Card Interaction Service | REST (HTTP/JSON) | Retrieves onboarded network identifiers for cards | Yes | `continuumCloCardInteractionService` |
| Deal Catalog Service | REST (HTTP/JSON) | Fetches deal details by inventory product id | Yes | `continuumDealCatalogService` |
| M3 Merchant Service | REST (HTTP/JSON) | Fetches merchant metadata and features by M3 merchant identifier | Yes | `continuumM3MerchantService` |
| M3 Places Service | REST (HTTP/JSON) | Fetches place details for redemption locations | No | `continuumM3PlacesService` |

### CLO Core Service Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: Configured via JTIER service discovery; accessed through `CloClient` and `CloServiceClient`
- **Auth**: JTIER service-to-service authentication
- **Purpose**: Central CLO offer lifecycle service. CLO Inventory Service calls it to create and update CLO offers when inventory products are created or modified, to create claims when users claim offers, and to manage card enrollment state as part of the consent flow.
- **Failure mode**: If unavailable, product creation/update operations that require offer synchronization will fail. Card enrollment flows will be blocked.
- **Circuit breaker**: Expected via JTIER/IS-Core HTTP client defaults

### CLO Card Interaction Service Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: Configured via JTIER service discovery
- **Auth**: JTIER service-to-service authentication
- **Purpose**: Provides onboarded network identifiers for cards, used during card enrollment and consent flows to verify card network status.
- **Failure mode**: If unavailable, card enrollment verification may be degraded. Consent flows that require network identifier lookups will fail.
- **Circuit breaker**: Expected via JTIER/IS-Core HTTP client defaults

### Deal Catalog Service Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: Configured via JTIER service discovery; accessed through `DealCatalogClient`
- **Auth**: JTIER service-to-service authentication
- **Purpose**: Provides deal and product metadata used to enrich CLO inventory products during creation and update. The Product Service and CreateOrUpdateProductAggregator depend on deal catalog data to resolve pricing, contract terms, and deal attributes.
- **Failure mode**: If unavailable, product creation and update operations that require deal enrichment will fail.
- **Circuit breaker**: Expected via JTIER/IS-Core HTTP client defaults

### M3 Merchant Service Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: Configured via JTIER service discovery; accessed through `M3MerchantClient`
- **Auth**: JTIER service-to-service authentication
- **Purpose**: Provides merchant metadata and feature configuration by M3 merchant identifier. Used by the Merchant Service and External Service Integrations to fetch merchant aggregates for CLO inventory operations.
- **Failure mode**: If unavailable, merchant feature lookups will fail. Operations that require merchant metadata enrichment will be degraded.
- **Circuit breaker**: Expected via JTIER/IS-Core HTTP client defaults

### M3 Places Service Detail

- **Protocol**: HTTP/JSON
- **Base URL / SDK**: Configured via JTIER service discovery; accessed through `M3PlacesClient`
- **Auth**: JTIER service-to-service authentication
- **Purpose**: Provides place/location details for redemption locations. Used by the Merchant Service to resolve where CLO offers can be redeemed.
- **Failure mode**: If unavailable, redemption location resolution will be degraded. Non-critical for core inventory operations.
- **Circuit breaker**: Expected via JTIER/IS-Core HTTP client defaults

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| CLO Inventory Database | JDBC via JTIER DaaS Postgres | Primary relational data store for all inventory, consent, and related data | `continuumCloInventoryDb` |
| CLO Inventory Redis Cache | JTIER Redis cache | Caching layer for product and inventory data read performance | `continuumCloInventoryRedisCache` |

## Consumed By

Upstream consumers are tracked in the central architecture model. Known consumers include:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| CLO platform services | REST (HTTP/JSON) | Query and manage CLO inventory products, units, and reservations |
| Consumer-facing applications | REST (HTTP/JSON) | Read CLO inventory for offer display and claim flows |
| Merchant tooling | REST (HTTP/JSON) | Configure merchant CLO features and view inventory state |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- All external HTTP integrations use JTIER/IS-Core HTTP client infrastructure, which provides configurable timeouts, retry policies, and connection pooling
- The Health & Observability component (`CloServiceHealthCheck`) monitors the health of critical dependencies including database connectivity and downstream service reachability
- Dropwizard metrics and metrics-sma provide real-time monitoring of dependency latency and error rates
- The three-tier caching strategy (in-memory -> Redis -> PostgreSQL) provides resilience against temporary database performance degradation for read operations
