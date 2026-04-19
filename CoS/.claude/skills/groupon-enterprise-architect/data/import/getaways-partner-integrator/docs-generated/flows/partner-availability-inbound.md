---
service: "getaways-partner-integrator"
title: "Partner Availability Inbound"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "partner-availability-inbound"
flow_type: synchronous
trigger: "Inbound SOAP ARI message from a channel manager (SiteMinder, TravelgateX, or APS)"
participants:
  - "siteminderChannelManager_6b1c"
  - "travelGateXChannelManager_43c2"
  - "apsChannelManager_8d21"
  - "continuumGetawaysPartnerIntegrator"
  - "soapApi"
  - "getawaysPartnerIntegrator_mappingService"
  - "getawaysPartnerIntegrator_inventoryClient"
  - "getawaysPartnerIntegrator_persistenceLayer"
  - "continuumGetawaysPartnerIntegratorDb"
  - "getawaysInventoryService_5e8a"
architecture_ref: "components-getawaysPartnerIntegratorComponents"
---

# Partner Availability Inbound

## Summary

A hotel channel manager (SiteMinder via `/SiteConnectService`, TravelgateX via `/TravelGateXARI`, or APS via `/GetawaysPartnerARI`) sends an inbound SOAP message containing ARI (Availability, Rates, and Inventory) data for one or more hotel properties. The service authenticates the request using WS-Security, routes the message to the mapping service for validation and processing, optionally fetches inventory hierarchy from the Getaways Inventory Service, and persists the updated mapping state to MySQL.

## Trigger

- **Type**: api-call (inbound SOAP)
- **Source**: External channel manager (SiteMinder, TravelgateX, or APS) — triggered when the channel manager has new availability or rate data to push
- **Frequency**: On demand — driven by hotel property updates at the channel manager

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SiteMinder / TravelgateX / APS | Sends inbound ARI SOAP message | `siteminderChannelManager_6b1c`, `travelGateXChannelManager_43c2`, `apsChannelManager_8d21` |
| SOAP API | Receives and authenticates inbound SOAP request | `soapApi` |
| Mapping Service | Validates and processes ARI data; coordinates inventory lookup | `getawaysPartnerIntegrator_mappingService` |
| Inventory Service Client | Fetches inventory hierarchy from Getaways Inventory Service | `getawaysPartnerIntegrator_inventoryClient` |
| Getaways Inventory Service | Returns inventory hierarchy (hotels, rooms, rate plans) | `getawaysInventoryService_5e8a` |
| Persistence Layer | Reads and writes mapping records to MySQL | `getawaysPartnerIntegrator_persistenceLayer` |
| Getaways Partner Integrator DB | Stores updated hotel/room/rate plan mapping state | `continuumGetawaysPartnerIntegratorDb` |

## Steps

1. **Receives ARI SOAP request**: Channel manager sends a SOAP message to the appropriate endpoint (`/SiteConnectService`, `/TravelGateXARI`, or `/GetawaysPartnerARI`).
   - From: `siteminderChannelManager_6b1c` / `travelGateXChannelManager_43c2` / `apsChannelManager_8d21`
   - To: `soapApi`
   - Protocol: SOAP / WS-Security

2. **Authenticates WS-Security header**: SOAP API validates the WS-Security credentials in the message header using Apache CXF and WSS4J.
   - From: `soapApi`
   - To: `soapApi` (internal WS-Security interceptor)
   - Protocol: WS-Security (username token / message signing)

3. **Delegates to Mapping Service**: SOAP API passes the parsed ARI payload to the Mapping Service for business logic processing.
   - From: `soapApi`
   - To: `getawaysPartnerIntegrator_mappingService`
   - Protocol: Direct (in-process)

4. **Fetches existing mapping records**: Mapping Service reads current hotel/room/rate plan mappings from MySQL to identify which Groupon inventory identifiers correspond to the partner's ARI data.
   - From: `getawaysPartnerIntegrator_mappingService`
   - To: `getawaysPartnerIntegrator_persistenceLayer` → `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

5. **Fetches inventory hierarchy** (conditional): If the ARI data references identifiers not yet in the local mapping, the Inventory Service Client calls the Getaways Inventory Service to resolve hotel/room/rate plan hierarchy.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_inventoryClient`
   - To: `getawaysInventoryService_5e8a`
   - Protocol: REST / HTTP

6. **Validates and processes ARI data**: Mapping Service applies business validation rules to the ARI payload and updates the mapping records accordingly.
   - From: `getawaysPartnerIntegrator_mappingService`
   - To: `getawaysPartnerIntegrator_mappingService` (internal)
   - Protocol: Direct

7. **Persists updated mapping state**: Persistence Layer writes the updated hotel/room/rate plan mapping records to MySQL.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer`
   - To: `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

8. **Returns SOAP response**: SOAP API returns a success or fault response to the channel manager.
   - From: `soapApi`
   - To: `siteminderChannelManager_6b1c` / `travelGateXChannelManager_43c2` / `apsChannelManager_8d21`
   - Protocol: SOAP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| WS-Security authentication failure | CXF security interceptor rejects request | SOAP Fault returned to channel manager; request not processed |
| Inventory Service unavailable | HTTP call from `getawaysPartnerIntegrator_inventoryClient` fails | Mapping validation fails; SOAP Fault returned; no MySQL write |
| MySQL write failure | JDBC exception from persistence layer | Mapping not updated; SOAP Fault returned |
| Unknown partner identifier in ARI payload | Mapping Service validation rejects payload | SOAP Fault returned; no state change |

## Sequence Diagram

```
ChannelManager -> soapApi: SOAP ARI message (WS-Security header)
soapApi -> soapApi: Validate WS-Security credentials (WSS4J)
soapApi -> mappingService: Process ARI payload
mappingService -> persistenceLayer: Read existing mapping records
persistenceLayer -> MySQL: SELECT hotel/room/rate mappings
MySQL --> persistenceLayer: Mapping records
persistenceLayer --> mappingService: Current mappings
mappingService -> inventoryClient: Fetch inventory hierarchy (if needed)
inventoryClient -> getawaysInventoryService: GET /inventory/hierarchy
getawaysInventoryService --> inventoryClient: Hotel/room/rate plan data
inventoryClient --> mappingService: Inventory hierarchy
mappingService -> persistenceLayer: Write updated mappings
persistenceLayer -> MySQL: INSERT/UPDATE mapping records
MySQL --> persistenceLayer: OK
persistenceLayer --> mappingService: Done
mappingService --> soapApi: Processing result
soapApi --> ChannelManager: SOAP response (success or fault)
```

## Related

- Architecture dynamic view: `components-getawaysPartnerIntegratorComponents`
- Related flows: [Partner Reservation Inbound](partner-reservation-inbound.md), [Kafka Partner Inbound Stream](kafka-partner-inbound-stream.md), [MBus Inventory Worker Outbound](mbus-inventory-worker-outbound.md)
