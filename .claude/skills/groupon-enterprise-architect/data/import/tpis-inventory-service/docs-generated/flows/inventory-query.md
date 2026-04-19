---
service: "tpis-inventory-service"
title: "Inventory Query"
generated: "2026-03-03"
type: flow
flow_name: "inventory-query"
flow_type: synchronous
trigger: "API request from internal Continuum service"
participants:
  - "continuumThirdPartyInventoryService"
  - "continuumThirdPartyInventoryDb"
architecture_ref: ""
---

# Inventory Query

## Summary

This flow describes how internal Continuum services query the Third Party Inventory Service for third-party inventory data. Multiple services -- including Deal Service, Deal Management API, MyGroupons, Unit Tracer, SPOG Gateway, MDS Feed Job, and others -- call TPIS HTTP APIs to retrieve inventory products, units, availability status, and booking details. TPIS reads from its MySQL database and returns the requested data.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum services (via direct HTTP or Lazlo API gateway)
- **Frequency**: Per-request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Requesting Service | Initiates query for third-party inventory data | Various (see Consumed By in integrations.md) |
| Lazlo API Gateway | Routes API requests to TPIS (optional) | `continuumApiLazloService` |
| Third Party Inventory Service | Processes query and returns inventory data | `continuumThirdPartyInventoryService` |
| 3rd Party Inventory DB | Serves persisted inventory events and product data | `continuumThirdPartyInventoryDb` |

## Steps

1. **Receive inventory query**: An internal Continuum service sends an HTTP request to TPIS for inventory data (products, units, availability, booking details).
   - From: Requesting service (or `continuumApiLazloService`)
   - To: `continuumThirdPartyInventoryService`
   - Protocol: HTTP/REST

2. **Query database**: TPIS queries the MySQL database for the requested inventory data.
   - From: `continuumThirdPartyInventoryService`
   - To: `continuumThirdPartyInventoryDb`
   - Protocol: JDBC

3. **Return results**: TPIS formats and returns the inventory data to the requesting service.
   - From: `continuumThirdPartyInventoryService`
   - To: Requesting service
   - Protocol: HTTP/REST (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inventory not found | Return 404 or empty result | Consumer handles absence gracefully |
| Database query failure | Return 5xx error | Consumer retries or falls back |
| Request validation error | Return 4xx error | Consumer corrects request |

## Sequence Diagram

```
RequestingService -> continuumApiLazloService: HTTP request for inventory data
continuumApiLazloService -> continuumThirdPartyInventoryService: Route request
continuumThirdPartyInventoryService -> continuumThirdPartyInventoryDb: Query inventory data (JDBC)
continuumThirdPartyInventoryDb --> continuumThirdPartyInventoryService: Return results
continuumThirdPartyInventoryService --> continuumApiLazloService: HTTP response (JSON)
continuumApiLazloService --> RequestingService: Forward response
```

## Related

- Related flows: [Partner Inventory Sync](partner-inventory-sync.md), [Data Replication](data-replication.md)
