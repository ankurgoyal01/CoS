---
service: "epods"
title: "Availability Sync Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "availability-sync-flow"
flow_type: scheduled
trigger: "Quartz scheduler fires on configured interval"
participants:
  - "continuumEpodsService"
  - "continuumEpodsPostgres"
  - "continuumEpodsRedis"
  - "mindbodyApi"
  - "bookerApi"
  - "messageBus"
  - "continuumCalendarService"
  - "continuumIngestionService"
architecture_ref: "dynamic-epods-availability-sync"
---

# Availability Sync Flow

## Summary

The Availability Sync Flow is a scheduled background job that polls partner systems (MindBody, Booker, and others) at regular intervals to retrieve current availability data (bookable time slots, capacity counts). EPODS stores the refreshed data in Redis for fast API reads, persists canonical records to PostgreSQL, and publishes `AvailabilityUpdate` events to the message bus so downstream services (Calendar Service, Ingestion) can react to changes.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler configured via `jtier-quartz-bundle`
- **Frequency**: Periodic — interval configured in service properties (exact cron not discoverable from architecture model)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| EPODS Service | Orchestrates the sync job; polls partners; publishes events | `continuumEpodsService` |
| EPODS Postgres | Source of partner mapping records; target for persisted availability data | `continuumEpodsPostgres` |
| EPODS Redis | Cache target for refreshed availability data; distributed lock holder | `continuumEpodsRedis` |
| MindBody API | Partner system polled for availability data | `mindbodyApi` |
| Booker API | Partner system polled for availability data | `bookerApi` |
| Message Bus | Receives `AvailabilityUpdate` events for downstream fanout | `messageBus` |
| Calendar Service | Downstream consumer of availability updates for calendar slot management | `continuumCalendarService` |
| Ingestion Service | Downstream consumer of availability updates for the ingestion pipeline | `continuumIngestionService` |

## Steps

1. **Quartz job fires**: The `jtier-quartz-bundle` scheduler triggers the availability sync job on its configured interval.
   - From: Quartz scheduler
   - To: `continuumEpodsService`
   - Protocol: direct (in-process)

2. **Acquire sync lock**: EPODS acquires a distributed lock in Redis to prevent multiple service instances from running concurrent sync jobs for the same partner/deal set.
   - From: `continuumEpodsService`
   - To: `continuumEpodsRedis`
   - Protocol: Redis

3. **Load active mappings**: EPODS queries `continuumEpodsPostgres` for the set of active deal-to-partner mappings that require availability polling.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

4. **Poll partner for availability**: For each active mapping, EPODS calls the target partner API (MindBody or Booker) to retrieve current available slots and capacity.
   - From: `continuumEpodsService`
   - To: `mindbodyApi` or `bookerApi`
   - Protocol: REST

5. **Translate partner availability to Groupon model**: EPODS maps partner slot/capacity data back to Groupon deal, product, and unit identifiers.
   - From: `continuumEpodsService`
   - To: `continuumEpodsService` (internal)
   - Protocol: direct

6. **Update Redis availability cache**: EPODS writes the translated availability data to Redis for fast access by the `/v1/availability` endpoint.
   - From: `continuumEpodsService`
   - To: `continuumEpodsRedis`
   - Protocol: Redis

7. **Persist availability snapshot**: EPODS writes or updates availability records in `continuumEpodsPostgres` for durability and audit.
   - From: `continuumEpodsService`
   - To: `continuumEpodsPostgres`
   - Protocol: JDBC

8. **Publish AvailabilityUpdate event**: For each changed availability record, EPODS publishes an `AvailabilityUpdate` event to the message bus.
   - From: `continuumEpodsService`
   - To: `messageBus`
   - Protocol: JMS/STOMP

9. **Release sync lock**: EPODS releases the distributed lock in Redis.
   - From: `continuumEpodsService`
   - To: `continuumEpodsRedis`
   - Protocol: Redis

10. **Downstream consumers react**: Calendar Service and Ingestion Service consume `AvailabilityUpdate` events from the message bus and update their own data accordingly.
    - From: `messageBus`
    - To: `continuumCalendarService`, `continuumIngestionService`
    - Protocol: JMS/STOMP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Partner API unavailable during poll | `failsafe` retry with backoff; circuit breaker opens after threshold | Availability for that partner not updated; stale cache served; `epods.availability.sync.failures` metric incremented |
| Redis lock acquisition failure (concurrent job) | Lock contention detected; job skips this cycle | No-op; next scheduled cycle will run normally |
| Redis cache write failure | Log error; data still persisted to PostgreSQL | Availability API reads fall back to PostgreSQL (higher latency) |
| PostgreSQL write failure | Log error; retry on next cycle | Availability event not published for this cycle |
| Message bus publish failure | Retry via `jtier-messagebus-client` | Downstream calendar/ingestion updates delayed until retry succeeds |
| Partial partner failure (one of N partners fails) | Continue processing remaining partners; log failure for failed partner | Availability for failed partner is stale; others updated normally |

## Sequence Diagram

```
QuartzScheduler -> EPODS: Trigger availability sync job
EPODS -> EpodsRedis: Acquire distributed sync lock
EPODS -> EpodsPostgres: Load active deal-to-partner mappings
EPODS -> PartnerAPI (MindBody/Booker): Poll availability per mapping
PartnerAPI --> EPODS: Availability slots and capacity
EPODS -> EPODS: Translate to Groupon domain model
EPODS -> EpodsRedis: Write availability cache
EPODS -> EpodsPostgres: Persist availability snapshot
EPODS -> MessageBus: Publish AvailabilityUpdate events
EPODS -> EpodsRedis: Release sync lock
MessageBus -> CalendarService: Consume AvailabilityUpdate
MessageBus -> IngestionService: Consume AvailabilityUpdate
```

## Related

- Architecture dynamic view: `dynamic-epods-availability-sync`
- Related flows: [Webhook Processing Flow](webhook-processing-flow.md), [Booking Flow](booking-flow.md)
