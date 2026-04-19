---
service: "grouponlive-inventory-service-jtier"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - "gliveInventoryService"
    - "continuumGliveInventoryDatabase"
    - "continuumRedisCache"
---

# Architecture Context

## System Context

The Groupon Live Inventory Service JTier sits within the **Continuum** platform as the authoritative inventory and ticketing integration layer for Groupon Live. It is called by upstream Groupon checkout and ordering services to check event availability, hold seats via reservations, and confirm purchases. The service connects outward to multiple third-party ticketing partner APIs (Provenue, Telecharge, AXS, Ticketmaster) and maintains its own MySQL database of products, events, reservations, orders, and venue credentials. A Redis cache is used to store OAuth access tokens obtained from partner APIs, reducing redundant authentication calls.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Groupon Live Inventory Service | `gliveInventoryService` | Service | JTier / Dropwizard | 5.14.1 | JTier service exposing REST API for inventory, reservations, and purchases |
| Glive Inventory MySQL | `continuumGliveInventoryDatabase` | Database | MySQL | 5.6+ | Primary data store for products, events, reservations, orders, and venue credentials |
| Redis Cache | `continuumRedisCache` | Cache | Redis | managed | Token and data cache for partner API authentication tokens |

## Components by Container

### Groupon Live Inventory Service (`gliveInventoryService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`grouponliveInventoryServiceJtier_apiResources`) | Exposes JAX-RS REST endpoints for inventory, reservations, purchases, events, products, merchants, and vendor credentials | Jersey / JAX-RS |
| Inventory Services (`inventoryServices`) | Contains business logic for inventory lookups, reservation orchestration, purchase processing, and vendor management | Java |
| Partner Integrations (`partnerIntegrations`) | Implements Retrofit HTTP clients and request-parameter providers for Provenue, Telecharge, AXS, and Ticketmaster partner APIs | Retrofit2 |
| Data Access Layer (`grouponliveInventoryServiceJtier_dataAccess`) | JDBI3 DAOs and row mappers for reading and writing to MySQL tables | JDBI3 |
| Redis Cache Service (`cache`) | Manages Jedis connections and stores/retrieves OAuth tokens for partner API calls | Jedis |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `grouponliveInventoryServiceJtier_apiResources` | `inventoryServices` | Invokes business logic for each inbound API request | In-process |
| `inventoryServices` | `grouponliveInventoryServiceJtier_dataAccess` | Reads and writes product, event, reservation, and order data | JDBI |
| `inventoryServices` | `partnerIntegrations` | Calls partner-specific handlers to perform reservations and purchases | In-process |
| `inventoryServices` | `cache` | Stores and retrieves cached data and partner OAuth tokens | In-process |
| `partnerIntegrations` | `cache` | Uses token cache to avoid redundant partner API authentication | In-process |
| `gliveInventoryService` | `continuumGliveInventoryDatabase` | Reads and writes inventory data | JDBC |
| `gliveInventoryService` | `continuumRedisCache` | Caches tokens and data | Redis |
| `gliveInventoryService` | `provenueApi_34fcfd` | Fetches inventory, reservations, and purchases | HTTPS/JSON |
| `gliveInventoryService` | `telechargeApi_18e9fb` | Fetches ticketing data and orders | HTTPS/JSON |

## Architecture Diagram References

- System context: `contexts-gliveInventoryService`
- Container: `containers-gliveInventoryService`
- Component: `components-gliveInventoryService`
