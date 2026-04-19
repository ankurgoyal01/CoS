---
service: "online_booking_3rd_party"
title: "Webhook Processing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "webhook-processing"
flow_type: event-driven
trigger: "Inbound HTTP POST from third-party provider system"
participants:
  - "continuumOnlineBooking3rdPartyApi"
  - "continuumOnlineBooking3rdPartyMysql"
  - "continuumOnlineBooking3rdPartyRedis"
  - "continuumAppointmentsEngine"
  - "continuumAvailabilityEngine"
  - "messageBus"
architecture_ref: "dynamic-merchant-mapping-request-flow"
---

# Webhook Processing

## Summary

The webhook processing flow handles inbound push events from third-party provider systems. When a provider notifies the service of a booking change or availability update, the API validates the inbound payload, authenticates the source via API key, persists the change to MySQL, and enqueues asynchronous jobs to propagate the update to the Appointment Engine and Availability Engine. A domain event is subsequently published to the Booking Engine topic.

## Trigger

- **Type**: event
- **Source**: Third-party provider system (Xola, Genbook, etc.) POST to `/v3/webhooks/bookings` or `/v3/webhooks/availability`
- **Frequency**: On-demand (provider-initiated; frequency determined by provider event rate)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Public API Endpoints | Receives and validates inbound webhook payload | `continuumOnlineBooking3rdPartyApi` / `apiPublicEndpoints` |
| Mapping Domain | Authenticates source and resolves affected mapping | `continuumOnlineBooking3rdPartyApi` / `apiMappingDomain` |
| Async Dispatch | Enqueues async propagation jobs | `continuumOnlineBooking3rdPartyApi` / `apiAsyncDispatch` |
| MySQL | Persists webhook-sourced state changes | `continuumOnlineBooking3rdPartyMysql` |
| Redis | Resque job queue for async propagation | `continuumOnlineBooking3rdPartyRedis` |
| Appointments Engine | Receives reservation updates derived from booking webhooks | `continuumAppointmentsEngine` |
| Availability Engine | Receives availability updates derived from availability webhooks | `continuumAvailabilityEngine` |
| Message Bus | Receives published 3rd-party domain events | `messageBus` |

## Steps

1. **Receive Webhook**: Provider POSTs event payload to `/v3/webhooks/bookings` or `/v3/webhooks/availability`
   - From: `emeaBtos` (provider system)
   - To: `continuumOnlineBooking3rdPartyApi` / `apiPublicEndpoints`
   - Protocol: HTTP/JSON

2. **Authenticate Source**: Validates API key in request headers against stored access tokens
   - From: `apiPublicEndpoints`
   - To: `apiMappingDomain`
   - Protocol: Direct (Rails in-process)

3. **Resolve Mapping**: Looks up the merchant place and mapping associated with the provider reference in the payload
   - From: `apiMappingDomain`
   - To: `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

4. **Persist Change**: Writes updated reservation or availability snapshot to MySQL
   - From: `apiMappingDomain`
   - To: `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

5. **Enqueue Propagation Jobs**: Dispatches async jobs to propagate changes to downstream services
   - From: `apiAsyncDispatch`
   - To: `continuumOnlineBooking3rdPartyRedis`
   - Protocol: Resque (Redis)

6. **Propagate to Appointments Engine** (async): Worker applies reservation lifecycle update
   - From: `continuumOnlineBooking3rdPartyWorkers` / `workerProviderSync`
   - To: `continuumAppointmentsEngine`
   - Protocol: HTTP/JSON

7. **Propagate to Availability Engine** (async): Worker pushes updated availability state
   - From: `continuumOnlineBooking3rdPartyWorkers` / `workerProviderSync`
   - To: `continuumAvailabilityEngine`
   - Protocol: HTTP/JSON

8. **Publish Domain Event** (async): Publishes normalized event to `jms.topic.BookingEngine.3rdParty.Events`
   - From: `workerEventPublisher`
   - To: `messageBus`
   - Protocol: STOMP/JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid API key | Return HTTP 401; reject payload | Provider webhook not processed |
| Unknown mapping reference | Return HTTP 422; payload rejected | Provider receives error; must retry or report |
| MySQL write failure | Return HTTP 500; provider retries | Deferred to provider retry |
| Async job failure | Resque retry with backoff | Downstream propagation delayed until retry succeeds |

## Sequence Diagram

```
emeaBtos -> apiPublicEndpoints: POST /v3/webhooks/bookings (or /availability)
apiPublicEndpoints -> apiMappingDomain: Authenticate and validate payload
apiMappingDomain -> continuumOnlineBooking3rdPartyMysql: Resolve mapping and persist change
apiPublicEndpoints -> apiAsyncDispatch: Enqueue propagation jobs
apiAsyncDispatch -> continuumOnlineBooking3rdPartyRedis: Enqueue Resque jobs
apiPublicEndpoints --> emeaBtos: HTTP 200 OK
workerProviderSync -> continuumAppointmentsEngine: Apply reservation update (async)
workerProviderSync -> continuumAvailabilityEngine: Push availability update (async)
workerEventPublisher -> messageBus: Publish BookingEngine.3rdParty.Events (async)
```

## Related

- Architecture dynamic view: `dynamic-merchant-mapping-request-flow`
- Related flows: [Merchant Place Polling](merchant-place-polling.md), [Appointment Event Consumption](appointment-event-consumption.md)
