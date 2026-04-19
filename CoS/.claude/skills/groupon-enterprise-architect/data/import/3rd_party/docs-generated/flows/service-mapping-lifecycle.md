---
service: "online_booking_3rd_party"
title: "Service Mapping Lifecycle"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "service-mapping-lifecycle"
flow_type: synchronous
trigger: "API call from merchant operator or Booking Engine service"
participants:
  - "continuumOnlineBooking3rdPartyApi"
  - "continuumOnlineBooking3rdPartyMysql"
  - "continuumOnlineBooking3rdPartyRedis"
  - "continuumAvailabilityEngine"
  - "continuumAppointmentsEngine"
architecture_ref: "dynamic-merchant-mapping-request-flow"
---

# Service Mapping Lifecycle

## Summary

The service mapping lifecycle flow covers the creation, update, and deletion of mappings between Groupon deal options/services and third-party provider service offerings. A merchant operator or Booking Engine service calls the V3 API to manage these mappings. The API persists changes to MySQL, synchronizes relevant state with the Availability Engine and Appointment Engine, and enqueues async jobs for any follow-up synchronization.

## Trigger

- **Type**: api-call
- **Source**: Merchant operator or internal Booking Engine service via `POST/PUT/DELETE /v3/services`
- **Frequency**: On-demand (triggered by merchant onboarding, deal configuration changes, or service updates)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Public API Endpoints | Receives and routes the mapping request | `continuumOnlineBooking3rdPartyApi` / `apiPublicEndpoints` |
| Mapping Domain | Validates and applies the mapping state transition | `continuumOnlineBooking3rdPartyApi` / `apiMappingDomain` |
| External Client Adapters | Syncs relevant state to Availability Engine and Appointments Engine | `continuumOnlineBooking3rdPartyApi` / `apiExternalClients` |
| Async Dispatch | Enqueues follow-up synchronization jobs | `continuumOnlineBooking3rdPartyApi` / `apiAsyncDispatch` |
| MySQL | Persists mapping records | `continuumOnlineBooking3rdPartyMysql` |
| Redis | Resque queue for async follow-up jobs | `continuumOnlineBooking3rdPartyRedis` |
| Availability Engine | Receives upserted service/place state | `continuumAvailabilityEngine` |
| Appointments Engine | Receives aligned option metadata | `continuumAppointmentsEngine` |

## Steps

1. **Receive Mapping Request**: API receives `POST`, `PUT`, or `DELETE` on `/v3/services`
   - From: Caller (merchant operator or internal service)
   - To: `continuumOnlineBooking3rdPartyApi` / `apiPublicEndpoints`
   - Protocol: REST / HTTP/JSON

2. **Validate and Apply Domain Logic**: Mapping domain validates the request, resolves the merchant place, and applies the state transition
   - From: `apiPublicEndpoints`
   - To: `apiMappingDomain`
   - Protocol: Direct (Rails in-process)

3. **Persist Mapping Record**: Writes the created/updated/deleted service mapping to MySQL
   - From: `apiMappingDomain`
   - To: `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

4. **Upsert Availability Service State**: Notifies Availability Engine of the new or updated service configuration
   - From: `apiExternalClients`
   - To: `continuumAvailabilityEngine`
   - Protocol: HTTP/JSON

5. **Align Appointment Option Metadata**: Notifies Appointment Engine of any option alignment required
   - From: `apiExternalClients`
   - To: `continuumAppointmentsEngine`
   - Protocol: HTTP/JSON

6. **Enqueue Follow-up Sync**: Dispatches an async job for any provider-side synchronization that should happen in the background
   - From: `apiAsyncDispatch`
   - To: `continuumOnlineBooking3rdPartyRedis`
   - Protocol: Resque (Redis)

7. **Return Response**: API returns the created/updated mapping record to the caller
   - From: `continuumOnlineBooking3rdPartyApi`
   - To: Caller
   - Protocol: REST / HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid mapping payload | Return HTTP 422 with validation errors | Caller must fix and retry |
| Merchant place not found | Return HTTP 404 | Mapping not created |
| Availability Engine failure | Inline error; mapping persisted in MySQL but AE not updated | Inconsistent state until async retry |
| MySQL write failure | Return HTTP 500 | Mapping not persisted; caller retries |

## Sequence Diagram

```
Caller -> apiPublicEndpoints: POST/PUT/DELETE /v3/services
apiPublicEndpoints -> apiMappingDomain: Validate and apply mapping state transition
apiMappingDomain -> continuumOnlineBooking3rdPartyMysql: Persist mapping record
apiExternalClients -> continuumAvailabilityEngine: Upsert service/place state
apiExternalClients -> continuumAppointmentsEngine: Align option metadata
apiAsyncDispatch -> continuumOnlineBooking3rdPartyRedis: Enqueue follow-up sync job
apiPublicEndpoints --> Caller: Return mapping response (HTTP 200/201)
```

## Related

- Architecture dynamic view: `dynamic-merchant-mapping-request-flow`
- Related flows: [Authorization Flow](authorization-flow.md), [Merchant Place Polling](merchant-place-polling.md)
