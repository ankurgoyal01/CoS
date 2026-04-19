---
service: "maris"
title: "Hotel Reservation Booking"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "hotel-reservation-booking"
flow_type: synchronous
trigger: "API call — POST /inventory/v1/reservations"
participants:
  - "continuumTravelInventoryService"
  - "marisMySql"
  - "unknown_expediarapidapi_12b321ae"
  - "continuumOrdersService"
  - "messageBus"
architecture_ref: "components-continuum-travel-inventory-service-maris"
---

# Hotel Reservation Booking

## Summary

This flow creates a confirmed hotel reservation by booking an itinerary with the Expedia Rapid API, persisting reservation and inventory unit records in `marisMySql`, and initiating payment authorization with the Orders Service. It is the core transactional flow for Groupon Getaways hotel purchases. Upon success, an inventory unit update event is published to the MBus.

## Trigger

- **Type**: api-call
- **Source**: Groupon commerce checkout flow (internal caller)
- **Frequency**: Per-request (on-demand, triggered by customer hotel purchase)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Commerce / Checkout caller | Initiates reservation creation request | Internal Continuum service |
| MARIS Service | Orchestrates booking, persistence, and payment authorization | `continuumTravelInventoryService` |
| Expedia Rapid API | Creates the hotel itinerary booking | `unknown_expediarapidapi_12b321ae` (stub) |
| MARIS MySQL | Persists reservation, unit, status log, and Expedia response | `marisMySql` |
| Orders Service | Authorizes payment for the reservation | `continuumOrdersService` |
| MBus | Receives published inventory unit update event | `messageBus` |

## Steps

1. **Receives reservation creation request**: Caller sends POST to `/inventory/v1/reservations` with hotel, room, guest, and payment context
   - From: Commerce / Checkout caller
   - To: `continuumTravelInventoryService` (API Resources)
   - Protocol: HTTP/JSON

2. **Validates request and resolves identifiers**: Validates incoming payload; resolves any legacy product identifiers via Deal Catalog Service if required
   - From: `continuumTravelInventoryService` (Core Orchestration)
   - To: `continuumDealCatalogService` (if legacy ID resolution needed)
   - Protocol: HTTP/JSON

3. **Books itinerary with Expedia Rapid API**: Sends authenticated booking request to Expedia Rapid with guest, room, and date details
   - From: `continuumTravelInventoryService` (Downstream Clients)
   - To: Expedia Rapid API (`unknown_expediarapidapi_12b321ae`)
   - Protocol: HTTPS REST

4. **Persists reservation and unit records**: Writes new reservation record, inventory unit record, Expedia booking response payload, and initial status log entry to `marisMySql`
   - From: `continuumTravelInventoryService` (Persistence Layer)
   - To: `marisMySql`
   - Protocol: JDBC

5. **Authorizes payment with Orders Service**: Calls Orders Service to authorize payment capture for the reservation unit
   - From: `continuumTravelInventoryService` (Downstream Clients)
   - To: `continuumOrdersService`
   - Protocol: HTTP/JSON

6. **Publishes inventory unit update event**: Publishes `InventoryUnits.Updated.Mrgetaways` event to MBus to notify downstream consumers of the new unit
   - From: `continuumTravelInventoryService` (Message Bus Handlers)
   - To: `messageBus`
   - Protocol: JMS

7. **Returns reservation confirmation**: Returns reservation ID, unit ID, and booking confirmation to the caller
   - From: `continuumTravelInventoryService`
   - To: Commerce / Checkout caller
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Expedia Rapid API rejects booking | Return error to caller; do not persist reservation | Caller receives booking failure; no unit created |
| `marisMySql` write failure after Expedia booking | Attempt compensating cancellation of Expedia itinerary; return error | System attempts to cancel booked itinerary; caller receives error |
| Orders Service payment authorization failure | Attempt to cancel Expedia itinerary; clean up persisted records | Reservation rolled back; caller receives payment failure |
| MBus publish failure | Log error; unit and reservation state already persisted | Downstream consumers may not receive update; operational alert triggered |
| Deal Catalog identifier resolution failure | Return validation error to caller | Caller receives 4xx; no booking attempted |

## Sequence Diagram

```
Caller -> MARIS: POST /inventory/v1/reservations
MARIS -> DealCatalogService: Resolve product identifier (if needed)
DealCatalogService --> MARIS: Resolved identifier
MARIS -> ExpediaRapidAPI: POST book itinerary (HTTPS)
ExpediaRapidAPI --> MARIS: Booking confirmation + itinerary ID
MARIS -> marisMySql: INSERT reservation, unit, status_log, expedia_response (JDBC)
MARIS -> OrdersService: POST authorize payment (HTTP/JSON)
OrdersService --> MARIS: Payment authorization response
MARIS -> MBus: PUBLISH InventoryUnits.Updated.Mrgetaways (JMS)
MARIS --> Caller: Reservation confirmation response
```

## Related

- Architecture component view: `components-continuum-travel-inventory-service-maris`
- Related flows: [Hotel Room Availability](hotel-room-availability.md), [Unit Status Change Processing](unit-status-change-processing.md), [Scheduled Cancellation Processing](scheduled-cancellation-processing.md)
