---
service: "getaways-payment-reconciliation"
title: "Inventory Reservation Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "inventory-reservation-ingestion"
flow_type: event-driven
trigger: "MBus inventory-units-updated message"
participants:
  - "getawaysPaymentReconciliation_messageBusConsumer"
  - "messageBusProcessor"
  - "marisClient"
  - "jdbiDaos"
  - "continuumGetawaysPaymentReconciliationDb"
architecture_ref: "components-getaways-payment-reconciliation-components"
---

# Inventory Reservation Ingestion

## Summary

This event-driven flow captures Getaways reservation data as it is created or updated in the inventory system. When the Maris service publishes an inventory-units-updated message to the MBus JMS topic, the Message Bus Consumer delivers it to the Message Bus Processor, which fetches the full inventory unit details from the Maris HTTP API and persists a reservation record to MySQL. These reservation records are the reference data used in invoice reconciliation.

## Trigger

- **Type**: event
- **Source**: MBus topic `messageBusInventoryUnitsUpdatedTopic` (JMS)
- **Frequency**: Per inventory update event; volume driven by Getaways booking activity

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus Consumer | Subscribes to MBus topic; delivers raw message to processor | `getawaysPaymentReconciliation_messageBusConsumer` |
| Message Bus Processor | Orchestrates unit lookup and persistence | `messageBusProcessor` |
| Maris Client | HTTP client for inventory unit details lookup | `marisClient` |
| JDBI DAOs | Persists the reservation record to MySQL | `jdbiDaos` |
| Getaways Payment Reconciliation DB | Stores the reservation record | `continuumGetawaysPaymentReconciliationDb` |

## Steps

1. **Receive MBus message**: `getawaysPaymentReconciliation_messageBusConsumer` receives an inventory-units-updated JMS message from the `messageBusInventoryUnitsUpdatedTopic` topic.
   - From: `messageBusInventoryUnitsUpdatedTopic`
   - To: `getawaysPaymentReconciliation_messageBusConsumer`
   - Protocol: JMS

2. **Deliver to processor**: Consumer delivers the message payload to `messageBusProcessor`.
   - From: `getawaysPaymentReconciliation_messageBusConsumer`
   - To: `messageBusProcessor`
   - Protocol: direct (in-process)

3. **Fetch inventory unit details**: `messageBusProcessor` calls `marisClient.getUnit(unitId, requestId)`, which issues an HTTP GET to the Maris Inventory API at the configured `marisUrl` format string (e.g., `/units/{unitId}`).
   - From: `marisClient`
   - To: Maris Inventory API (`marisInventoryApi_unk_61b2`)
   - Protocol: HTTP GET

4. **Receive unit response**: Maris returns a `GetUnitsResponse` containing a single `UnitResponse` with inventory unit details.
   - From: Maris Inventory API
   - To: `marisClient`
   - Protocol: HTTP

5. **Persist reservation**: `messageBusProcessor` calls `jdbiDaos` to store the reservation record derived from the unit response.
   - From: `messageBusProcessor`
   - To: `jdbiDaos` / `continuumGetawaysPaymentReconciliationDb`
   - Protocol: JDBC/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Maris HTTP call fails | Exception propagates from `RestClient`; message processing fails | Reservation not persisted; message may be redelivered by MBus |
| Maris returns multiple units (not exactly one) | `Iterables.getOnlyElement` throws `IllegalArgumentException` | Message processing fails |
| DB write failure | JDBI exception propagates | Reservation not persisted |
| JMS connectivity lost | JTier MBus client manages reconnect | Messages buffered by broker until reconnected |

## Sequence Diagram

```
MBus(messageBusInventoryUnitsUpdatedTopic) -> messageBusConsumer: JMS message (unitId, requestId)
messageBusConsumer -> messageBusProcessor: deliver message
messageBusProcessor -> marisClient: getUnit(unitId, requestId)
marisClient -> MarisInventoryAPI: GET /units/{unitId} (X-Request-Id: requestId)
MarisInventoryAPI --> marisClient: GetUnitsResponse { units: [UnitResponse] }
marisClient --> messageBusProcessor: UnitResponse
messageBusProcessor -> jdbiDaos: store reservation
jdbiDaos -> MySQL: INSERT reservation record
MySQL --> jdbiDaos: OK
```

## Related

- Architecture dynamic view: `components-getaways-payment-reconciliation-components`
- Related flows: [Invoice Reconciliation and Payment](invoice-reconciliation-and-payment.md), [Scheduled Reconciliation Worker](scheduled-reconciliation-worker.md)
