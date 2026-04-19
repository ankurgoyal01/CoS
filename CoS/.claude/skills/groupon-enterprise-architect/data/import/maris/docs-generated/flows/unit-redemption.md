---
service: "maris"
title: "Unit Redemption"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "unit-redemption"
flow_type: synchronous
trigger: "API call — POST /inventory/v1/units/{id}/redemption"
participants:
  - "continuumTravelInventoryService"
  - "marisMySql"
  - "messageBus"
architecture_ref: "components-continuum-travel-inventory-service-maris"
---

# Unit Redemption

## Summary

This flow records the redemption of a hotel inventory unit — marking that the customer has used or checked in for the hotel stay associated with the unit. The redemption is persisted in `marisMySql`, a status log entry is written, and a unit update event is published to the MBus to notify downstream consumers of the state change.

## Trigger

- **Type**: api-call
- **Source**: Groupon merchant or operations tool recording a hotel check-in or stay completion
- **Frequency**: Per-request (on-demand, once per fulfilled hotel stay)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Redemption caller (merchant / ops tool) | Initiates redemption recording | Internal Groupon service |
| MARIS Service | Validates request, updates unit state, and publishes event | `continuumTravelInventoryService` |
| MARIS MySQL | Persists redemption state and status log entry | `marisMySql` |
| MBus | Receives published unit update event | `messageBus` |

## Steps

1. **Receives redemption request**: Caller sends POST to `/inventory/v1/units/{id}/redemption` with unit identifier and redemption context
   - From: Redemption caller
   - To: `continuumTravelInventoryService` (API Resources)
   - Protocol: HTTP/JSON

2. **Validates unit and redemption eligibility**: Reads current unit state from `marisMySql`; verifies unit is in a redeemable status
   - From: `continuumTravelInventoryService` (Core Orchestration / Persistence Layer)
   - To: `marisMySql`
   - Protocol: JDBC

3. **Records redemption in `marisMySql`**: Updates unit status to redeemed, writes redemption details, and appends status log entry
   - From: `continuumTravelInventoryService` (Persistence Layer)
   - To: `marisMySql`
   - Protocol: JDBC

4. **Publishes unit update event**: Publishes `InventoryUnits.Updated.Mrgetaways` event to MBus reflecting the redeemed status
   - From: `continuumTravelInventoryService` (Message Bus Handlers)
   - To: `messageBus`
   - Protocol: JMS

5. **Returns redemption confirmation**: Returns success response with updated unit state to the caller
   - From: `continuumTravelInventoryService`
   - To: Redemption caller
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unit not found | Return 404 to caller | Redemption not recorded |
| Unit not in redeemable status | Return 4xx with reason to caller | Redemption rejected; unit state unchanged |
| `marisMySql` write failure | Return 5xx to caller | Redemption not persisted; caller should retry |
| MBus publish failure | Log error; redemption already persisted | Downstream consumers may not receive update; operational alert triggered |

## Sequence Diagram

```
Caller -> MARIS: POST /inventory/v1/units/{id}/redemption
MARIS -> marisMySql: SELECT unit by ID (JDBC)
marisMySql --> MARIS: Current unit state
MARIS -> marisMySql: UPDATE unit status = redeemed, INSERT status_log (JDBC)
MARIS -> MBus: PUBLISH InventoryUnits.Updated.Mrgetaways (JMS)
MARIS --> Caller: Redemption confirmation response
```

## Related

- Architecture component view: `components-continuum-travel-inventory-service-maris`
- Related flows: [Unit Status Change Processing](unit-status-change-processing.md), [Hotel Reservation Booking](hotel-reservation-booking.md)
