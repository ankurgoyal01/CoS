---
service: "channel-manager-integrator-synxis"
title: "ARI Push to Kafka Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "ari-push-to-kafka"
flow_type: event-driven
trigger: "SynXis CRS initiates a SOAP pushAvailability, pushInventory, or pushRate call to /soap/CMService"
participants:
  - "synxisCrs"
  - "soapAriIngress"
  - "mappingPersistence"
  - "inventoryHierarchyClient"
  - "continuumTravelInventoryService"
  - "kafkaAriPublisher"
  - "continuumKafkaBroker"
architecture_ref: "dynamic-ari-push-to-kafka-flow"
---

# ARI Push to Kafka Flow

## Summary

This flow describes how SynXis CRS pushes Availability, Rates, and Inventory (ARI) updates into the Continuum platform. SynXis calls the `CMService` SOAP endpoint; the service validates the payload by resolving internal mappings and fetching hotel hierarchy data from Inventory Service, then publishes a validated ARI event to Kafka for downstream consumers. The flow is entirely inbound-triggered and event-driven: no polling occurs.

## Trigger

- **Type**: event (inbound SOAP push)
- **Source**: SynXis CRS calls `pushAvailability`, `pushInventory`, or `pushRate` on `/soap/CMService`
- **Frequency**: On demand, driven by SynXis CRS update schedule

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SynXis CRS | Initiates the ARI push via SOAP | `synxisCrs` |
| SOAP ARI Ingress | Receives and orchestrates ARI push processing | `soapAriIngress` |
| Mapping and Reservation Persistence | Resolves external-to-internal mapping; logs request/response | `mappingPersistence` |
| Inventory Hierarchy Client | Fetches hotel hierarchy for validation | `inventoryHierarchyClient` |
| Continuum Travel Inventory Service | Provides hotel hierarchy data | `continuumTravelInventoryService` |
| ARI Kafka Publisher | Publishes validated ARI message to Kafka | `kafkaAriPublisher` |
| Continuum Kafka Broker | Receives and durably stores the ARI event | `continuumKafkaBroker` |

## Steps

1. **Receive ARI push**: SynXis CRS sends a `pushAvailability`, `pushInventory`, or `pushRate` SOAP request to the `CMService` endpoint.
   - From: `synxisCrs`
   - To: `soapAriIngress`
   - Protocol: SOAP over HTTPS

2. **Resolve mapping and validate identifiers**: `soapAriIngress` queries the persistence layer to resolve external hotel/room identifiers to internal Continuum identifiers and logs the incoming request.
   - From: `soapAriIngress`
   - To: `mappingPersistence`
   - Protocol: Direct (in-process JDBI/MySQL)

3. **Fetch hotel hierarchy for validation**: `soapAriIngress` delegates to `inventoryHierarchyClient` to retrieve the hotel hierarchy required to validate the ARI payload.
   - From: `soapAriIngress`
   - To: `inventoryHierarchyClient`
   - Protocol: Direct (in-process)

4. **Retrieve hierarchy data**: `inventoryHierarchyClient` calls the Inventory Service REST API to fetch the hotel hierarchy.
   - From: `inventoryHierarchyClient`
   - To: `continuumTravelInventoryService`
   - Protocol: HTTPS/JSON

5. **Emit validated ARI message**: `soapAriIngress` passes the validated ARI payload to `kafkaAriPublisher` for publishing.
   - From: `soapAriIngress`
   - To: `kafkaAriPublisher`
   - Protocol: Direct (in-process)

6. **Publish ARI event to Kafka**: `kafkaAriPublisher` produces the ARI event to the Kafka topic on `continuumKafkaBroker`.
   - From: `kafkaAriPublisher`
   - To: `continuumKafkaBroker`
   - Protocol: Kafka

7. **Return SOAP response**: `soapAriIngress` returns a success or fault SOAP response to SynXis CRS.
   - From: `soapAriIngress`
   - To: `synxisCrs`
   - Protocol: SOAP over HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Mapping not found for incoming identifiers | Validation fails in `mappingPersistence` lookup | SOAP fault returned to SynXis CRS; event not published to Kafka |
| Inventory Service unavailable | `inventoryHierarchyClient` receives HTTP error or timeout | ARI validation cannot complete; SOAP fault returned to SynXis; event not published |
| Kafka broker unavailable | `kafkaAriPublisher` publish fails | SOAP fault or error response returned to SynXis CRS; event not published downstream |
| Invalid ARI payload (OVal validation) | Payload validation rejects the message | SOAP fault returned to SynXis CRS; request logged to MySQL |

## Sequence Diagram

```
SynXis CRS       -> soapAriIngress          : pushAvailability / pushInventory / pushRate (SOAP)
soapAriIngress   -> mappingPersistence      : Resolve mapping identifiers and log request (JDBI/MySQL)
soapAriIngress   -> inventoryHierarchyClient: Request hotel hierarchy data (in-process)
inventoryHierarchyClient -> continuumTravelInventoryService : GET hierarchy (HTTPS/JSON)
continuumTravelInventoryService --> inventoryHierarchyClient : Hierarchy response
soapAriIngress   -> kafkaAriPublisher       : Emit validated ARI message (in-process)
kafkaAriPublisher -> continuumKafkaBroker   : Publish ARI event (Kafka)
soapAriIngress   --> SynXis CRS             : SOAP success response
```

## Related

- Architecture dynamic view: `dynamic-ari-push-to-kafka-flow`
- Related flows: [Reservation and Cancellation Worker Flow](reservation-cancellation-worker.md)
