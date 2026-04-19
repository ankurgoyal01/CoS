---
service: "channel-manager-integrator-travelclick"
title: "Hotel Reservation Processing"
generated: "2026-03-03"
type: flow
flow_name: "hotel-reservation-processing"
flow_type: asynchronous
trigger: "Reservation message delivered to MBus reservation topic"
participants:
  - "messageBus"
  - "continuumChannelManagerIntegratorTravelclick"
  - "cmiTc_mbusConsumer"
  - "cmiTc_travelclickClient"
  - "cmiTc_persistence"
  - "travelclickPlatform"
  - "continuumChannelManagerIntegratorTravelclickMySql"
architecture_ref: "components-continuum-channel-manager-integrator-travelclick"
---

# Hotel Reservation Processing

## Summary

When a Groupon customer books a hotel stay through the Getaways platform, an upstream booking service publishes a reservation message to an MBus topic. This service consumes that message, fetches any required hotel product data from the Getaways Inventory service, builds an OTA XML reservation request conforming to the OpenTravel Alliance standard, and delivers it to TravelClick. The outcome (success or failure) is persisted to MySQL and a response message is published back to MBus.

## Trigger

- **Type**: event
- **Source**: MBus reservation topic (message schema defined in `channel-manager-async-schema` 0.0.22)
- **Frequency**: On demand, per booking event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus | Delivers reservation message to the service | `messageBus` |
| MBus Consumer | Receives and dispatches the reservation event | `cmiTc_mbusConsumer` |
| Inventory Client | Fetches hotel hierarchy and product data if required | `cmiTc_inventoryClient` |
| TravelClick Client | Builds and sends OTA XML reservation request | `cmiTc_travelclickClient` |
| Persistence Layer | Stores reservation record and request/response audit log | `cmiTc_persistence` |
| MySQL | Durable storage for reservation and audit data | `continuumChannelManagerIntegratorTravelclickMySql` |
| TravelClick | Receives the OTA reservation XML and confirms or rejects | `travelclickPlatform` |
| MBus | Receives the processing outcome response message | `messageBus` |

## Steps

1. **Receive reservation message**: The MBus consumer receives a reservation event from the MBus reservation topic.
   - From: `messageBus`
   - To: `cmiTc_mbusConsumer`
   - Protocol: MBus

2. **Read existing reservation record**: The MBus consumer checks MySQL for an existing reservation record to detect duplicates or prior state.
   - From: `cmiTc_mbusConsumer`
   - To: `cmiTc_persistence` -> `continuumChannelManagerIntegratorTravelclickMySql`
   - Protocol: JDBI/JDBC

3. **Fetch hotel product data**: If hotel hierarchy or product metadata is needed to construct the OTA request, the inventory client calls the Getaways Inventory service.
   - From: `cmiTc_mbusConsumer` -> `cmiTc_inventoryClient`
   - To: `getawaysInventoryService`
   - Protocol: HTTP/REST

4. **Build and send OTA reservation request**: The TravelClick client marshals the reservation data into an OTA XML `OTA_HotelResNotifRQ` request and sends it to TravelClick via HTTPS.
   - From: `cmiTc_travelclickClient`
   - To: `travelclickPlatform`
   - Protocol: HTTPS / OTA XML

5. **Log request to MySQL**: Before or after sending, the TravelClick client persists the outbound OTA request payload to the request audit table.
   - From: `cmiTc_travelclickClient`
   - To: `cmiTc_persistence` -> `continuumChannelManagerIntegratorTravelclickMySql`
   - Protocol: JDBI/JDBC

6. **Receive TravelClick response**: TravelClick returns an OTA XML response indicating success, warning, or error.
   - From: `travelclickPlatform`
   - To: `cmiTc_travelclickClient`
   - Protocol: HTTPS / OTA XML

7. **Log response to MySQL**: The TravelClick client persists the response payload and status to the response audit table.
   - From: `cmiTc_travelclickClient`
   - To: `cmiTc_persistence` -> `continuumChannelManagerIntegratorTravelclickMySql`
   - Protocol: JDBI/JDBC

8. **Write reservation record**: The MBus consumer updates or creates the reservation record with the final status.
   - From: `cmiTc_mbusConsumer`
   - To: `cmiTc_persistence` -> `continuumChannelManagerIntegratorTravelclickMySql`
   - Protocol: JDBI/JDBC

9. **Publish response message**: The service publishes a channel manager response message to MBus indicating the outcome.
   - From: `continuumChannelManagerIntegratorTravelclick`
   - To: `messageBus`
   - Protocol: MBus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| TravelClick returns OTA error response | Log response to MySQL; publish error response to MBus | Upstream notified of failure; message may be retried |
| TravelClick unreachable (network/timeout) | Message routed to MBus DLQ | DLQ holds message for retry once TravelClick recovers |
| Getaways Inventory service unavailable | Request fails before OTA call | Message may be routed to DLQ; reservation not sent to TravelClick |
| MySQL write failure | Processing halted; message may be nacked to MBus | DLQ-backed retry |
| Duplicate reservation message | Prior record detected in MySQL; processing skipped or idempotent update | No duplicate sent to TravelClick |

## Sequence Diagram

```
MBus -> cmiTc_mbusConsumer: Reservation message
cmiTc_mbusConsumer -> cmiTc_persistence: Read existing reservation record
cmiTc_persistence -> MySQL: SELECT reservation
MySQL --> cmiTc_persistence: Record (or empty)
cmiTc_mbusConsumer -> cmiTc_inventoryClient: Fetch hotel product data
cmiTc_inventoryClient -> getawaysInventoryService: GET hotel hierarchy
getawaysInventoryService --> cmiTc_inventoryClient: Hotel product response
cmiTc_mbusConsumer -> cmiTc_travelclickClient: Process reservation
cmiTc_travelclickClient -> cmiTc_persistence: Write request log
cmiTc_travelclickClient -> travelclickPlatform: POST OTA reservation XML
travelclickPlatform --> cmiTc_travelclickClient: OTA response XML
cmiTc_travelclickClient -> cmiTc_persistence: Write response log
cmiTc_mbusConsumer -> cmiTc_persistence: Write reservation record
continuumChannelManagerIntegratorTravelclick -> MBus: Publish response message
```

## Related

- Architecture component view: `components-continuum-channel-manager-integrator-travelclick`
- Related flows: [Hotel Cancellation Processing](hotel-cancellation-processing.md)
- Events: [Events](../events.md)
