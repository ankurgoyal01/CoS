---
service: "channel-manager-integrator-travelclick"
title: "Hotel Cancellation Processing"
generated: "2026-03-03"
type: flow
flow_name: "hotel-cancellation-processing"
flow_type: asynchronous
trigger: "Cancellation message delivered to MBus cancellation topic"
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

# Hotel Cancellation Processing

## Summary

When a Groupon customer cancels a hotel booking, an upstream Getaways service publishes a cancellation message to an MBus topic. This service consumes that message, builds an OTA XML cancellation request, and delivers it to TravelClick to release the reservation at the hotel. The outcome is persisted to MySQL and a response message is published back to MBus for the upstream system.

## Trigger

- **Type**: event
- **Source**: MBus cancellation topic (message schema defined in `channel-manager-async-schema` 0.0.22)
- **Frequency**: On demand, per cancellation event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus | Delivers cancellation message | `messageBus` |
| MBus Consumer | Receives and dispatches the cancellation event | `cmiTc_mbusConsumer` |
| TravelClick Client | Builds and sends OTA XML cancellation request | `cmiTc_travelclickClient` |
| Persistence Layer | Stores cancellation record and request/response audit log | `cmiTc_persistence` |
| MySQL | Durable storage for cancellation and audit data | `continuumChannelManagerIntegratorTravelclickMySql` |
| TravelClick | Receives the OTA cancellation XML and releases the booking | `travelclickPlatform` |
| MBus | Receives the processing outcome response message | `messageBus` |

## Steps

1. **Receive cancellation message**: The MBus consumer receives a cancellation event from the MBus cancellation topic.
   - From: `messageBus`
   - To: `cmiTc_mbusConsumer`
   - Protocol: MBus

2. **Read existing reservation record**: The MBus consumer retrieves the original reservation record from MySQL to obtain TravelClick-specific reference identifiers needed for the cancellation.
   - From: `cmiTc_mbusConsumer`
   - To: `cmiTc_persistence` -> `continuumChannelManagerIntegratorTravelclickMySql`
   - Protocol: JDBI/JDBC

3. **Build and send OTA cancellation request**: The TravelClick client marshals the cancellation data into an OTA XML cancellation request and sends it to TravelClick via HTTPS.
   - From: `cmiTc_travelclickClient`
   - To: `travelclickPlatform`
   - Protocol: HTTPS / OTA XML

4. **Log request to MySQL**: The TravelClick client persists the outbound OTA cancellation request to the audit log.
   - From: `cmiTc_travelclickClient`
   - To: `cmiTc_persistence` -> `continuumChannelManagerIntegratorTravelclickMySql`
   - Protocol: JDBI/JDBC

5. **Receive TravelClick response**: TravelClick returns an OTA XML response confirming or rejecting the cancellation.
   - From: `travelclickPlatform`
   - To: `cmiTc_travelclickClient`
   - Protocol: HTTPS / OTA XML

6. **Log response to MySQL**: The TravelClick client persists the response payload and status.
   - From: `cmiTc_travelclickClient`
   - To: `cmiTc_persistence` -> `continuumChannelManagerIntegratorTravelclickMySql`
   - Protocol: JDBI/JDBC

7. **Update cancellation record**: The MBus consumer writes the final cancellation status to MySQL.
   - From: `cmiTc_mbusConsumer`
   - To: `cmiTc_persistence` -> `continuumChannelManagerIntegratorTravelclickMySql`
   - Protocol: JDBI/JDBC

8. **Publish response message**: The service publishes a channel manager response message to MBus indicating the cancellation outcome.
   - From: `continuumChannelManagerIntegratorTravelclick`
   - To: `messageBus`
   - Protocol: MBus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Original reservation record not found in MySQL | Processing fails; message routed to DLQ | DLQ holds for investigation |
| TravelClick returns OTA error on cancellation | Log response; publish failure response to MBus | Upstream notified; manual resolution may be needed |
| TravelClick unreachable | Message routed to MBus DLQ | DLQ holds message for retry |
| MySQL write failure | Processing halted; message nacked | DLQ-backed retry |

## Sequence Diagram

```
MBus -> cmiTc_mbusConsumer: Cancellation message
cmiTc_mbusConsumer -> cmiTc_persistence: Read reservation record
cmiTc_persistence -> MySQL: SELECT reservation by ID
MySQL --> cmiTc_persistence: Reservation record
cmiTc_mbusConsumer -> cmiTc_travelclickClient: Process cancellation
cmiTc_travelclickClient -> cmiTc_persistence: Write request log
cmiTc_travelclickClient -> travelclickPlatform: POST OTA cancellation XML
travelclickPlatform --> cmiTc_travelclickClient: OTA response XML
cmiTc_travelclickClient -> cmiTc_persistence: Write response log
cmiTc_mbusConsumer -> cmiTc_persistence: Update cancellation record
continuumChannelManagerIntegratorTravelclick -> MBus: Publish response message
```

## Related

- Architecture component view: `components-continuum-channel-manager-integrator-travelclick`
- Related flows: [Hotel Reservation Processing](hotel-reservation-processing.md)
- Events: [Events](../events.md)
