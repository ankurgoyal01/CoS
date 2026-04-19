---
service: "deal_centre_api"
title: "Inventory Event Processing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "inventory-event-processing"
flow_type: event-driven
trigger: "Inventory event delivered by Message Bus"
participants:
  - "messageBus"
  - "continuumDealCentreApi"
  - "dca_messageBusIntegration"
  - "dca_domainServices"
  - "dca_persistenceLayer"
  - "continuumDealCentrePostgres"
architecture_ref: "dynamic-inventory-event-processing"
---

# Inventory Event Processing

## Summary

The Message Bus delivers an inbound inventory event to Deal Centre API. The `dca_messageBusIntegration` component receives the event and triggers Domain Services to process the inventory state change. The updated inventory is persisted to the Deal Centre PostgreSQL database, ensuring the local state stays consistent with the broader Continuum inventory picture.

## Trigger

- **Type**: event
- **Source**: `messageBus` — inventory channel; event published by another Continuum service or by this service itself (round-trip scenario)
- **Frequency**: On demand — triggered whenever an inventory event is published to the Message Bus

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers the inventory event to the consumer | `messageBus` |
| Message Bus Integration | Receives the event and triggers domain processing | `dca_messageBusIntegration` |
| Domain Services | Applies inventory business logic and state changes | `dca_domainServices` |
| Persistence Layer | Writes updated inventory state to PostgreSQL | `dca_persistenceLayer` |
| Deal Centre Postgres | Stores the updated inventory record | `continuumDealCentrePostgres` |

## Steps

1. **Delivers inventory event**: Message Bus routes the inventory event to Deal Centre API's registered consumer.
   - From: `messageBus`
   - To: `dca_messageBusIntegration`
   - Protocol: MBus

2. **Triggers domain processing**: Message Bus Integration deserializes the event payload and invokes Domain Services.
   - From: `dca_messageBusIntegration`
   - To: `dca_domainServices`
   - Protocol: Spring (direct internal call)

3. **Applies inventory logic**: Domain Services validates the event and determines the required state change (e.g., adjust available inventory, mark option sold out).
   - From: `dca_domainServices`
   - To: `dca_domainServices`
   - Protocol: internal

4. **Persists updated inventory**: Domain Services instructs Persistence Layer to update the inventory record in PostgreSQL.
   - From: `dca_persistenceLayer`
   - To: `continuumDealCentrePostgres`
   - Protocol: JPA/JDBC

5. **Acknowledges event**: Message Bus Integration acknowledges the event to the broker on successful processing.
   - From: `dca_messageBusIntegration`
   - To: `messageBus`
   - Protocol: MBus ACK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed event payload | `dca_messageBusIntegration` fails deserialization; event not processed | Event may be retried or sent to DLQ by MBus infrastructure |
| PostgreSQL write failure | JPA exception; message not acknowledged | MBus redelivers event (at-least-once semantics); potential duplicate processing |
| Duplicate event (at-least-once delivery) | Domain Services applies idempotent update if implemented; otherwise may double-apply | Inventory state may be incorrect if idempotency not enforced |

## Sequence Diagram

```
messageBus -> dca_messageBusIntegration: inventory event (MBus)
dca_messageBusIntegration -> dca_domainServices: processInventoryEvent(payload)
dca_domainServices -> dca_persistenceLayer: updateInventory(optionId, newQuantity)
dca_persistenceLayer -> continuumDealCentrePostgres: UPDATE inventory (JPA/JDBC)
continuumDealCentrePostgres --> dca_persistenceLayer: OK
dca_persistenceLayer --> dca_domainServices: updated
dca_domainServices --> dca_messageBusIntegration: processing complete
dca_messageBusIntegration -> messageBus: ACK
```

## Related

- Architecture dynamic view: `dynamic-inventory-event-processing`
- Related flows: [Buyer Deal Purchase](buyer-deal-purchase.md), [Deal Catalog Sync](deal-catalog-sync.md)
