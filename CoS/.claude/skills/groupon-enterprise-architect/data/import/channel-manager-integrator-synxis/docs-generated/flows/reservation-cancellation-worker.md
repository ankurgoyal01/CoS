---
service: "channel-manager-integrator-synxis"
title: "Reservation and Cancellation Worker Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "reservation-cancellation-worker"
flow_type: asynchronous
trigger: "Inventory Service Worker publishes a RESERVE or CANCEL request message to MBus"
participants:
  - "inventoryServiceWorker"
  - "messageBus"
  - "mbusInboundProcessor"
  - "reservationCancellationService"
  - "mappingPersistence"
  - "synxisClient"
  - "synxisCrs"
  - "mbusOutboundPublisher"
architecture_ref: "dynamic-reservation-cancellation-worker-flow"
---

# Reservation and Cancellation Worker Flow

## Summary

This flow describes how CMI SynXis processes hotel reservation and cancellation requests originating from the Continuum Inventory Service Worker. The Inventory Service Worker publishes a RESERVE or CANCEL message to MBus; the `mbusInboundProcessor` consumes it and dispatches the business workflow to `reservationCancellationService`, which reads mapping and reservation state from MySQL, calls SynXis CRS via SOAP to execute the operation, persists the outcome, and publishes a success or failure response back to MBus for the Inventory Service Worker to consume.

> Note: The architecture dynamic view for this flow is disabled in the federation model because `inventoryServiceWorker` is a stub-only element not present in the central workspace. The flow steps below are derived from the commented-out dynamic view DSL (`reservation-cancellation-flow.dsl`) and the component relation model.

## Trigger

- **Type**: event (MBus message)
- **Source**: `inventoryServiceWorker` publishes a RESERVE or CANCEL request to MBus inbound topic
- **Frequency**: On demand, driven by hotel booking and cancellation activity

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Inventory Service Worker | Initiates reservation/cancellation by publishing MBus request | `inventoryServiceWorker` |
| MBus | Delivers request message; receives response message | `messageBus` |
| MBus Inbound Processor | Consumes request and dispatches to business service | `mbusInboundProcessor` |
| Reservation and Cancellation Service | Orchestrates the full reservation/cancellation business workflow | `reservationCancellationService` |
| Mapping and Reservation Persistence | Reads mapping; reads/writes reservation state | `mappingPersistence` |
| SynXis SOAP Client | Executes SOAP operation against SynXis CRS | `synxisClient` |
| SynXis CRS | External CRS that creates or cancels the reservation | `synxisCrs` |
| MBus Outbound Publisher | Publishes success or failure response to MBus | `mbusOutboundPublisher` |

## Steps

1. **Publish RESERVE or CANCEL request**: Inventory Service Worker publishes a reservation or cancellation request message to the MBus inbound topic.
   - From: `inventoryServiceWorker`
   - To: `messageBus`
   - Protocol: MBus topic

2. **Deliver worker request**: MBus delivers the message to `mbusInboundProcessor`.
   - From: `messageBus`
   - To: `mbusInboundProcessor`
   - Protocol: MBus topic/queue

3. **Dispatch business workflow**: `mbusInboundProcessor` dispatches the request to `reservationCancellationService`.
   - From: `mbusInboundProcessor`
   - To: `reservationCancellationService`
   - Protocol: Direct (in-process)

4. **Read mapping and reservation state**: `reservationCancellationService` reads mapping configuration and current reservation state from MySQL.
   - From: `reservationCancellationService`
   - To: `mappingPersistence`
   - Protocol: Direct (in-process JDBI/MySQL)

5. **Call SynXis reservation or cancellation API**: `reservationCancellationService` instructs `synxisClient` to execute the appropriate SOAP operation (create reservation or cancel reservation) against SynXis CRS.
   - From: `reservationCancellationService`
   - To: `synxisClient`
   - Protocol: Direct (in-process)

6. **Execute ChannelConnect SOAP operation**: `synxisClient` calls the SynXis ChannelConnectService SOAP API.
   - From: `synxisClient`
   - To: `synxisCrs`
   - Protocol: SOAP over HTTPS

7. **Persist reservation outcome**: `reservationCancellationService` writes the reservation state transition (confirmation number, status, SOAP response log) to MySQL.
   - From: `reservationCancellationService`
   - To: `mappingPersistence`
   - Protocol: Direct (in-process JDBI/MySQL)

8. **Build and publish response payload**: `reservationCancellationService` instructs `mbusOutboundPublisher` to send the success or failure response.
   - From: `reservationCancellationService`
   - To: `mbusOutboundPublisher`
   - Protocol: Direct (in-process)

9. **Send response message**: `mbusOutboundPublisher` publishes the reservation/cancellation response to the MBus Inventory Service Worker topic.
   - From: `mbusOutboundPublisher`
   - To: `messageBus`
   - Protocol: MBus topic

10. **Deliver success/failure response**: MBus delivers the response to `inventoryServiceWorker`.
    - From: `messageBus`
    - To: `inventoryServiceWorker`
    - Protocol: MBus topic/queue

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Mapping record not found for hotel/room | Validation fails in `mappingPersistence` lookup | Failure response published to MBus; reservation not created in SynXis |
| SynXis SOAP call fails (network or SOAP fault) | `synxisClient` returns error to `reservationCancellationService` | Failure response published to MBus; state persisted as failed in MySQL |
| MySQL unavailable | `mappingPersistence` throws database error | Workflow cannot proceed; no response published; message may be requeued depending on MBus config |
| MBus outbound publish fails | `mbusOutboundPublisher` unable to send | `inventoryServiceWorker` does not receive a response; may time out and retry the request |

## Sequence Diagram

```
inventoryServiceWorker  -> messageBus                   : Publish RESERVE/CANCEL request (MBus)
messageBus              -> mbusInboundProcessor         : Deliver worker request (MBus)
mbusInboundProcessor    -> reservationCancellationService : Dispatch business workflow (in-process)
reservationCancellationService -> mappingPersistence    : Read mapping and reservation state (JDBI/MySQL)
reservationCancellationService -> synxisClient          : Execute create/cancel operation (in-process)
synxisClient            -> synxisCrs                    : ChannelConnect SOAP call (SOAP over HTTPS)
synxisCrs               --> synxisClient                : SOAP response (confirmation / fault)
reservationCancellationService -> mappingPersistence    : Write reservation outcome (JDBI/MySQL)
reservationCancellationService -> mbusOutboundPublisher : Build and publish response (in-process)
mbusOutboundPublisher   -> messageBus                   : Send response message (MBus)
messageBus              -> inventoryServiceWorker       : Deliver success/failure response (MBus)
```

## Related

- Architecture dynamic view: `dynamic-reservation-cancellation-worker-flow` (disabled in federation; see `architecture/views/dynamics/reservation-cancellation-flow.dsl`)
- Related flows: [ARI Push to Kafka Flow](ari-push-to-kafka.md)
