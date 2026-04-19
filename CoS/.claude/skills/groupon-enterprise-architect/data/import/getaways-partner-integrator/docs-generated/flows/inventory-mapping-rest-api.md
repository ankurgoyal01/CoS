---
service: "getaways-partner-integrator"
title: "Inventory Mapping REST API"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "inventory-mapping-rest-api"
flow_type: synchronous
trigger: "REST API call (GET or PUT) from an internal Groupon consumer"
participants:
  - "continuumGetawaysPartnerIntegrator"
  - "getawaysPartnerIntegrator_restApi"
  - "getawaysPartnerIntegrator_mappingService"
  - "getawaysPartnerIntegrator_inventoryClient"
  - "getawaysPartnerIntegrator_persistenceLayer"
  - "continuumGetawaysPartnerIntegratorDb"
  - "getawaysInventoryService_5e8a"
architecture_ref: "components-getawaysPartnerIntegratorComponents"
---

# Inventory Mapping REST API

## Summary

Internal Groupon consumers (operations tooling, other Continuum services) call the REST API to retrieve or update hotel/room/rate plan mapping records that link Groupon inventory identifiers to partner channel manager identifiers. GET requests return current mapping state from MySQL; PUT requests create or update mappings, optionally triggering an inventory hierarchy lookup from the Getaways Inventory Service for validation.

## Trigger

- **Type**: api-call (REST)
- **Source**: Internal Groupon consumer — operations tooling, Continuum service, or admin workflow
- **Frequency**: On demand — driven by hotel onboarding, remapping, or administrative operations

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal Consumer | Initiates REST GET or PUT request | External to this service |
| REST API | Receives and routes the HTTP request | `getawaysPartnerIntegrator_restApi` |
| Mapping Service | Executes business logic for mapping retrieval or update | `getawaysPartnerIntegrator_mappingService` |
| Inventory Service Client | Fetches inventory hierarchy for validation on PUT (conditional) | `getawaysPartnerIntegrator_inventoryClient` |
| Getaways Inventory Service | Returns hotel/room/rate plan hierarchy | `getawaysInventoryService_5e8a` |
| Persistence Layer | Reads or writes mapping records in MySQL | `getawaysPartnerIntegrator_persistenceLayer` |
| Getaways Partner Integrator DB | Stores hotel/room/rate plan mapping records | `continuumGetawaysPartnerIntegratorDb` |

## Steps

### GET — Retrieve Mapping Records

1. **Receives GET request**: Internal consumer calls `GET /getaways/v2/channel_manager_integrator/mapping` with query parameters identifying the hotel, room, or rate plan.
   - From: Internal consumer
   - To: `getawaysPartnerIntegrator_restApi`
   - Protocol: REST / HTTP

2. **Delegates to Mapping Service**: REST API passes the request parameters to the Mapping Service.
   - From: `getawaysPartnerIntegrator_restApi`
   - To: `getawaysPartnerIntegrator_mappingService`
   - Protocol: Direct (in-process)

3. **Reads mapping records**: Mapping Service queries MySQL via the Persistence Layer for matching hotel/room/rate plan mapping records.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer`
   - To: `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

4. **Returns mapping data**: REST API serializes the mapping records and returns a JSON response.
   - From: `getawaysPartnerIntegrator_restApi`
   - To: Internal consumer
   - Protocol: REST / HTTP (JSON)

### PUT — Create or Update Mapping Records

1. **Receives PUT request**: Internal consumer calls `PUT /getaways/v2/channel_manager_integrator/mapping` with a JSON body containing new or updated mapping data.
   - From: Internal consumer
   - To: `getawaysPartnerIntegrator_restApi`
   - Protocol: REST / HTTP

2. **Delegates to Mapping Service**: REST API passes the request body to the Mapping Service for validation and processing.
   - From: `getawaysPartnerIntegrator_restApi`
   - To: `getawaysPartnerIntegrator_mappingService`
   - Protocol: Direct (in-process)

3. **Validates and fetches inventory hierarchy** (conditional): For new mappings, the Mapping Service calls the Getaways Inventory Service to verify that the referenced Groupon inventory identifiers exist.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_inventoryClient`
   - To: `getawaysInventoryService_5e8a`
   - Protocol: REST / HTTP

4. **Persists mapping record**: Mapping Service writes the created or updated mapping to MySQL.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer`
   - To: `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

5. **Returns success response**: REST API returns HTTP 200 or 201 with the persisted mapping record.
   - From: `getawaysPartnerIntegrator_restApi`
   - To: Internal consumer
   - Protocol: REST / HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid mapping identifiers in PUT body | Mapping Service validation rejects request | HTTP 400 returned; no MySQL write |
| Inventory Service returns 404 for unknown identifier | Inventory Client propagates error to Mapping Service | HTTP 422 or 400 returned; mapping not created |
| MySQL read failure on GET | JDBC exception | HTTP 500 returned |
| MySQL write failure on PUT | JDBC exception | HTTP 500 returned; no mapping persisted |

## Sequence Diagram

```
Consumer -> restApi: GET /getaways/v2/channel_manager_integrator/mapping
restApi -> mappingService: Retrieve mappings (query params)
mappingService -> persistenceLayer: SELECT mapping records
persistenceLayer -> MySQL: Query
MySQL --> persistenceLayer: Records
persistenceLayer --> mappingService: Mapping data
mappingService --> restApi: Mapping records
restApi --> Consumer: HTTP 200 JSON response

Consumer -> restApi: PUT /getaways/v2/channel_manager_integrator/mapping (body)
restApi -> mappingService: Validate and save mapping
mappingService -> inventoryClient: Verify inventory identifiers (if new)
inventoryClient -> getawaysInventoryService: GET /inventory/hierarchy
getawaysInventoryService --> inventoryClient: Hierarchy data
inventoryClient --> mappingService: Validation OK
mappingService -> persistenceLayer: INSERT/UPDATE mapping
persistenceLayer -> MySQL: Write
MySQL --> persistenceLayer: OK
mappingService --> restApi: Saved mapping
restApi --> Consumer: HTTP 200/201 JSON response
```

## Related

- Architecture dynamic view: `components-getawaysPartnerIntegratorComponents`
- Related flows: [Partner Availability Inbound](partner-availability-inbound.md), [Kafka Partner Inbound Stream](kafka-partner-inbound-stream.md)
