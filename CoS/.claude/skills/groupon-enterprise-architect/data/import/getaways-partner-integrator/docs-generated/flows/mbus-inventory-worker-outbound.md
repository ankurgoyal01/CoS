---
service: "getaways-partner-integrator"
title: "MBus Inventory Worker Outbound"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "mbus-inventory-worker-outbound"
flow_type: event-driven
trigger: "InventoryWorkerMessage received on Groupon MBus (grouponMessageBus_7a2d)"
participants:
  - "grouponMessageBus_7a2d"
  - "continuumGetawaysPartnerIntegrator"
  - "mbusWorker"
  - "getawaysPartnerIntegrator_mappingService"
  - "getawaysPartnerIntegrator_inventoryClient"
  - "getawaysPartnerIntegrator_persistenceLayer"
  - "continuumGetawaysPartnerIntegratorDb"
  - "getawaysInventoryService_5e8a"
architecture_ref: "components-getawaysPartnerIntegratorComponents"
---

# MBus Inventory Worker Outbound

## Summary

The MBus Worker component (`mbusWorker`) consumes `InventoryWorkerMessage` events from the Groupon MBus (JMS). Each message triggers a mapping workflow within the Mapping Service — reading and potentially updating hotel/room/rate plan mappings in MySQL and fetching inventory hierarchy from the Getaways Inventory Service when needed. Upon completion, the service publishes a new outbound `InventoryWorkerMessage` to the MBus to signal downstream inventory workers to proceed with further processing.

## Trigger

- **Type**: event (JMS / MBus message)
- **Source**: Upstream Groupon system or internal workflow publishes an `InventoryWorkerMessage` to the Groupon MBus
- **Frequency**: On demand — driven by inventory update workflows within the Continuum platform

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Groupon MBus | Brokers inbound and outbound InventoryWorkerMessage events | `grouponMessageBus_7a2d` |
| MBus Worker | Subscribes to MBus; receives and publishes InventoryWorkerMessage | `mbusWorker` |
| Mapping Service | Executes inventory mapping workflow triggered by the inbound message | `getawaysPartnerIntegrator_mappingService` |
| Inventory Service Client | Fetches inventory hierarchy for mapping resolution (conditional) | `getawaysPartnerIntegrator_inventoryClient` |
| Getaways Inventory Service | Returns hotel/room/rate plan hierarchy | `getawaysInventoryService_5e8a` |
| Persistence Layer | Reads and writes mapping records to MySQL | `getawaysPartnerIntegrator_persistenceLayer` |
| Getaways Partner Integrator DB | Stores hotel/room/rate plan mapping state | `continuumGetawaysPartnerIntegratorDb` |

## Steps

1. **Receives InventoryWorkerMessage**: MBus Worker receives an `InventoryWorkerMessage` from the Groupon MBus JMS broker via `jtier-messagebus-client`.
   - From: `grouponMessageBus_7a2d`
   - To: `mbusWorker`
   - Protocol: JMS / MBus

2. **Delegates to Mapping Service**: MBus Worker passes the message payload to the Mapping Service to execute the inventory mapping workflow.
   - From: `mbusWorker`
   - To: `getawaysPartnerIntegrator_mappingService`
   - Protocol: Direct (in-process)

3. **Reads current mapping state**: Mapping Service reads relevant hotel/room/rate plan mappings from MySQL to determine what action is needed.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer`
   - To: `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

4. **Fetches inventory hierarchy** (conditional): If mapping resolution requires up-to-date inventory data, Mapping Service calls the Getaways Inventory Service.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_inventoryClient`
   - To: `getawaysInventoryService_5e8a`
   - Protocol: REST / HTTP

5. **Executes mapping workflow**: Mapping Service processes the inventory worker task — validating identifiers, applying updates, and preparing the result.
   - From: `getawaysPartnerIntegrator_mappingService`
   - To: `getawaysPartnerIntegrator_mappingService` (internal)
   - Protocol: Direct

6. **Persists mapping changes**: Persistence Layer writes any mapping updates resulting from the workflow to MySQL.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer`
   - To: `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

7. **Publishes outbound InventoryWorkerMessage**: MBus Worker publishes a new `InventoryWorkerMessage` to the Groupon MBus to trigger downstream inventory worker processing.
   - From: `mbusWorker`
   - To: `grouponMessageBus_7a2d`
   - Protocol: JMS / MBus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inventory Service unavailable during mapping resolution | HTTP call fails; workflow cannot complete | Message not acknowledged; JMS redelivery applies; outbound message not published |
| MySQL read/write failure | JDBC exception; workflow aborted | Message not acknowledged; JMS redelivery applies |
| MBus publish failure on outbound message | JMS exception | Workflow result not propagated downstream; MBus broker-level retry |
| Malformed InventoryWorkerMessage payload | Deserialization exception in MBus Worker | Message not acknowledged; JMS redelivery; poison-pill risk if schema incompatible |

## Sequence Diagram

```
grouponMBus -> mbusWorker: InventoryWorkerMessage (JMS)
mbusWorker -> mappingService: Execute mapping workflow
mappingService -> persistenceLayer: Read current mappings
persistenceLayer -> MySQL: SELECT
MySQL --> persistenceLayer: Mapping records
persistenceLayer --> mappingService: Current state
mappingService -> inventoryClient: Fetch inventory hierarchy (if needed)
inventoryClient -> getawaysInventoryService: GET /inventory/hierarchy
getawaysInventoryService --> inventoryClient: Hierarchy data
inventoryClient --> mappingService: Resolved hierarchy
mappingService -> persistenceLayer: Write mapping updates
persistenceLayer -> MySQL: INSERT/UPDATE
MySQL --> persistenceLayer: OK
mappingService --> mbusWorker: Workflow complete
mbusWorker -> grouponMBus: Publish outbound InventoryWorkerMessage (JMS)
```

## Related

- Architecture dynamic view: `components-getawaysPartnerIntegratorComponents`
- Related flows: [Kafka Partner Inbound Stream](kafka-partner-inbound-stream.md), [Partner Availability Inbound](partner-availability-inbound.md)
