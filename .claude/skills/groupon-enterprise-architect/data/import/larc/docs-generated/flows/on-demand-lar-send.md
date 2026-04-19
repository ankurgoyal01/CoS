---
service: "larc"
title: "On-Demand LAR Send"
generated: "2026-03-03"
type: flow
flow_name: "on-demand-lar-send"
flow_type: synchronous
trigger: "HTTP PUT request from eTorch or Getaways extranet app"
participants:
  - "continuumTravelLarcService"
  - "continuumTravelLarcDatabase"
  - "continuumTravelInventoryService"
architecture_ref: "dynamic-larc-rate-update-flow"
---

# On-Demand LAR Send

## Summary

The on-demand LAR send flow allows internal operators (via eTorch or the Getaways extranet app) to immediately trigger a LAR computation and delivery for a specific hotel/room-type/rate-plan combination without waiting for the next scheduled worker cycle. This is used after a rate description mapping change or when a deal is newly set up and requires an initial LAR population.

## Trigger

- **Type**: api-call
- **Source**: eTorch or Getaways extranet app — HTTP PUT to `/v2/getaways/larc/hotels/{hotel_uuid}/room_types/{room_type_uuid}/rate_plans/{rate_plan_uuid}/rates`
- **Frequency**: On-demand — triggered by operator action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| eTorch / Extranet App | Initiates the on-demand LAR send request | External operator tool |
| LARC API Resources | Receives the PUT request, delegates to LarSender | `continuumTravelLarcService` / `larcApiResources` |
| LARC Rate Computation (LarSender) | Orchestrates RoomTypeLarCalculator and LivePricingJobHelper | `continuumTravelLarcService` / `larcRateComputation` |
| LARC Persistence Layer | Reads NightlyLar; writes LivePricingJob | `continuumTravelLarcService` / `larcDataAccess` |
| LARC Database | Provides NightlyLar data; stores LivePricingJob results | `continuumTravelLarcDatabase` |
| Travel Inventory Service | Provides rate plan details; receives computed LAR updates | `continuumTravelInventoryService` |

## Steps

1. **Receive API request**: `RatesResource` (JAX-RS) receives the PUT request at `/v2/getaways/larc/hotels/{hotel_uuid}/room_types/{room_type_uuid}/rate_plans/{rate_plan_uuid}/rates`. The `hotel_uuid`, `room_type_uuid`, and `rate_plan_uuid` are extracted from the path.
   - From: External caller (eTorch/extranet)
   - To: `larcApiResources`
   - Protocol: HTTP/REST

2. **Create LarSender and RoomTypeLarCalculator**: `RatesResource` instantiates `LarSender` with the provided UUIDs. `LarSender` creates a `RoomTypeLarCalculator` scoped to the specific `ratePlanUuid`, restricting computation to one rate plan.
   - From: `larcApiResources`
   - To: `larcRateComputation`
   - Protocol: Direct (in-process)

3. **Fetch rate plan from Inventory Service**: `RoomTypeLarCalculator` calls `InventoryServiceClient.getRatePlan()` for the specific `ratePlanUuid`. If the rate plan is not found, a 404 `LarcException` is thrown immediately.
   - From: `larcExternalClients`
   - To: `continuumTravelInventoryService`
   - Protocol: HTTP/JSON (Retrofit)

4. **Validate rate plan viability**: Checks that the rate plan is `ACTIVE` and has a non-null `productSetUuid`. Determines travel window (start/end date), flooring the start to today if it is in the past.
   - From: `larcRateComputation`
   - To: (internal)
   - Protocol: —

5. **Query NightlyLar for computed rates**: Reads `NightlyLar` records for the room type within the travel window. Selects the best rate per night (latest `ql2Timestamp`, lowest `amount` on tie).
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

6. **Send LAR update to Inventory Service**: Calls `InventoryServiceClient.updateQl2Prices()` with the constructed `InventoryServiceRates` payload.
   - From: `larcExternalClients`
   - To: `continuumTravelInventoryService`
   - Protocol: HTTP/JSON (Retrofit PUT)

7. **Record LivePricingJob**: `LivePricingJobHelper` records the live pricing job result (product set UUID, date range) into the LARC database for tracking.
   - From: `larcDataAccess`
   - To: `continuumTravelLarcDatabase`
   - Protocol: JDBC/MySQL

8. **Return HTTP 200**: `RatesResource` returns HTTP 200 OK to the caller upon completion.
   - From: `larcApiResources`
   - To: External caller (eTorch/extranet)
   - Protocol: HTTP/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Rate plan not found | `LarcException` HTTP 404 | 404 response returned to caller |
| Inventory Service timeout | `LarcException` wrapping `SocketTimeoutException` | Logged as `UPDATE_LAR_TIMED_OUT`; 500 response returned to caller |
| SQL error | `LarcException` HTTP 500 | 500 response returned to caller |
| Rate plan not active or no productSetUuid | LAR computation skipped silently | 200 returned; no rates sent to Inventory |
| No NightlyLar data found | `InventoryServiceRates.rates` is empty | Inventory Service not called; 200 returned; operator should verify QL2 ingestion has run |

## Sequence Diagram

```
eTorch/Extranet -> LARC API: PUT /v2/getaways/larc/hotels/{hotel_uuid}/room_types/{room_type_uuid}/rate_plans/{rate_plan_uuid}/rates
LARC API -> Travel Inventory Service: GET rate plan by ratePlanUuid
Travel Inventory Service --> LARC API: Rate plan details (startAt, endAt, productSetUuid, activeStatus)
LARC API -> LARC Database: Query NightlyLar by roomTypeUuid + travel window
LARC Database --> LARC API: NightlyLar records
LARC API -> Travel Inventory Service: PUT ql2Prices (computed LAR per night)
Travel Inventory Service --> LARC API: 200 OK
LARC API -> LARC Database: Write LivePricingJob record
LARC API --> eTorch/Extranet: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-larc-rate-update-flow`
- Related flows: [LAR Computation and Rate Update](lar-computation-rate-update.md), [Hotel and Rate Description Management](hotel-rate-description-management.md)
