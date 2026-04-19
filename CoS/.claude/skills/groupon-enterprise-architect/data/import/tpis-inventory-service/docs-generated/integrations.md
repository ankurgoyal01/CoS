---
service: "tpis-inventory-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

The Third Party Inventory Service integrates with one external system -- the 3rd-Party Inventory Systems representing partner platforms for travel, events, and goods inventory. The service has no outbound internal service dependencies defined in its own DSL (it only depends on its own database). However, TPIS is a heavily consumed service within the Continuum ecosystem, with 14+ internal services depending on it for third-party inventory data.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| 3rd-Party Inventory Systems | API | Partner platforms providing travel, events, and goods inventory and booking information | yes | `thirdPartyInventory` |

### 3rd-Party Inventory Systems Detail

- **Protocol**: API (HTTP/REST inferred)
- **Base URL / SDK**: Partner-specific endpoints (not discoverable from architecture DSL)
- **Auth**: Partner-specific authentication (not discoverable from architecture DSL)
- **Purpose**: External partner platforms that provide inventory, availability, and booking data that TPIS ingests and serves to the rest of the Continuum platform
- **Failure mode**: Partner unavailability would prevent inventory updates; stale data would be served from local DB
- **Circuit breaker**: Not discoverable from architecture DSL

## Internal Dependencies

The Third Party Inventory Service does not have outbound dependencies on other internal Continuum services defined in its architecture DSL. Its only internal dependency is its own MySQL database.

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| 3rd Party Inventory DB | JDBC | Reads and writes tpis events inventory data | `continuumThirdPartyInventoryDb` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Lazlo API Gateway | HTTP | Routes API requests to TPIS |
| Deal Service (Marketing) | HTTP | Fetches third-party inventory status |
| CLO Service | HTTP | Coordinates inventory sync |
| Breakage Reduction Service | HTTPS/JSON | Reads third-party inventory units/products |
| Calendar Service | HTTP | Calls third-party inventory APIs |
| Deal Management API | HTTP/JSON | Synchronizes third-party inventory products; inventory lookups |
| CS Groupon WebApp | HTTP | 3rd-party inventory operations |
| iTier 3PIP Service | HTTP | Uses TPIS booking flows and data |
| MyGroupons | HTTP | Fetches third-party inventory booking item details |
| Mailman | HTTP/JSON | Fetches partner inventory data |
| MDS Feed Job | HTTPS/JSON | Reads TPIS availability data for TTD feeds |
| Message2Ledger | HTTP/JSON | Fetches TPIS unit/product details |
| SPOG Gateway | HTTP/REST | Fetches inventory units for TPIS |
| Unit Tracer | HTTP | Queries inventory units |

## Dependency Health

Dependency health check, retry, and circuit breaker patterns for external partner integrations are not discoverable from the architecture DSL. Service owners should document resilience patterns here.
