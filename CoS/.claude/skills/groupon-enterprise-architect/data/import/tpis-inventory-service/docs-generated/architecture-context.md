---
service: "tpis-inventory-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumThirdPartyInventoryService", "continuumThirdPartyInventoryDb"]
---

# Architecture Context

## System Context

The Third Party Inventory Service sits within the Continuum Platform (`continuumSystem`), Groupon's core commerce engine. It bridges external partner inventory systems (`thirdPartyInventory`) with the rest of Groupon's internal services. The Continuum system integrates with partner inventory via API, and TPIS is the service responsible for persisting and serving that data internally. Numerous internal services -- including the Deal Service, Deal Management API, MyGroupons, Calendar Service, SPOG Gateway, Unit Tracer, and others -- consume TPIS data to power deal availability, booking flows, feed generation, and customer-facing inventory displays. Inventory data is also replicated to EDW and BigQuery for analytics.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Third Party Inventory Service | `continuumThirdPartyInventoryService` | Application | Java | Microservice that manages third-party inventory from external partners |
| 3rd Party Inventory DB | `continuumThirdPartyInventoryDb` | Database | MySQL | Persists TPIS events and inventory data |

## Components by Container

### Third Party Inventory Service (`continuumThirdPartyInventoryService`)

No components are currently defined in the architecture DSL for this container. Component-level decomposition is pending service owner contribution.

## Key Relationships

### Internal (within service boundary)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumThirdPartyInventoryService` | `continuumThirdPartyInventoryDb` | Reads and writes tpis events inventory data | JDBC |

### Central model (cross-service, owned by architecture repo)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumThirdPartyInventoryDb` | `edw` | Replicates data for analysis | -- |
| `continuumThirdPartyInventoryDb` | `bigQuery` | Replicates data for analysis | -- |
| `continuumApiLazloService` | `continuumThirdPartyInventoryService` | Routes API requests | -- |
| `continuumMarketingDealService` | `continuumThirdPartyInventoryService` | Fetches third-party inventory status | HTTP |

### Federated model (cross-service, owned by other service repos)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCloServiceApi` | `continuumThirdPartyInventoryService` | Coordinates inventory sync | -- |
| `continuumBreakageReductionService` | `continuumThirdPartyInventoryService` | Reads third-party inventory units/products | HTTPS/JSON |
| `continuumCalendarService` | `continuumThirdPartyInventoryService` | Calls third-party inventory APIs | -- |
| `continuumDealManagementApi` | `continuumThirdPartyInventoryService` | Synchronizes third-party inventory products | HTTP/JSON |
| `continuumCsWebApp` | `continuumThirdPartyInventoryService` | 3rd-party inventory operations | -- |
| `continuumThreePipService` | `continuumThirdPartyInventoryService` | Uses TPIS booking flows and data | -- |
| `continuumMygrouponsService` | `continuumThirdPartyInventoryService` | Fetches third-party inventory booking item details | -- |
| `continuumMailmanService` | `continuumThirdPartyInventoryService` | Fetches partner inventory data | HTTP/JSON |
| `continuumMdsFeedJob` | `continuumThirdPartyInventoryService` | Reads TPIS availability data for TTD feeds | HTTPS/JSON |
| `continuumMessage2LedgerService` | `continuumThirdPartyInventoryService` | Fetches TPIS unit/product details | HTTP/JSON |
| `continuumSpogGateway` | `continuumThirdPartyInventoryService` | Fetches inventory units for TPIS | HTTP/REST |
| `continuumUnitTracerService` | `continuumThirdPartyInventoryService` | Queries inventory units | -- |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Container (Inventory domain): `containers-continuum-inventory`
