---
service: "calendar-service"
title: "Availability Ingestion and Compilation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "availability-ingestion-compilation"
flow_type: asynchronous
trigger: "POST /v1/services/{id}/ingest_availability followed by Quartz compilation worker"
participants:
  - "continuumCalendarServiceCalSer"
  - "continuumCalendarUtility"
  - "continuumCalendarMySql"
  - "continuumCalendarRedis"
architecture_ref: "calendarServiceComponents"
---

# Availability Ingestion and Compilation

## Summary

This flow covers the two-stage process by which raw availability data is accepted from external sources and converted into queryable availability windows. Stage one is synchronous: the API hosts accept a raw availability payload via `POST /v1/services/{id}/ingest_availability` and store it in MySQL. Stage two is asynchronous: the utility workers (`continuumCalendarUtility`) run Quartz compilation jobs that read the raw data, compute compiled availability windows, persist the results back to MySQL, and invalidate the Redis cache so subsequent queries pick up the fresh data.

## Trigger

- **Type**: api-call (stage 1) + schedule (stage 2)
- **Source**: External booking partner or internal availability management service calls `POST /v1/services/{id}/ingest_availability`; Quartz scheduler in `continuumCalendarUtility` fires the compilation job on its configured schedule
- **Frequency**: On-demand ingestion; compilation runs on a scheduled cadence (exact interval not declared in architecture DSL)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Calendar Service API Hosts | Receives and stores raw ingestion payload | `continuumCalendarServiceCalSer` |
| API Resources | Routes the ingest request to availability handling | `apiResourcesCalSer` |
| Availability Core | Processes raw ingest payload and persists to MySQL | `availabilityCore` |
| Persistence Layer | Writes raw ingestion records and reads/writes compiled availability | `dataAccessCalSer` |
| Availability Engine MySQL DaaS | Stores both raw ingestion data and compiled availability records | `continuumCalendarMySql` |
| Calendar Service Utility Hosts | Runs background compilation Quartz jobs | `continuumCalendarUtility` |
| Calendar Service Redis Cache | Cache entries are invalidated post-compilation | `continuumCalendarRedis` |

## Steps

1. **Receive raw availability payload**: External caller sends `POST /v1/services/{id}/ingest_availability` with the raw availability data for a service.
   - From: external caller or availability management service
   - To: `apiResourcesCalSer`
   - Protocol: REST

2. **Store raw ingestion record**: `availabilityCore` via `dataAccessCalSer` writes the raw availability payload to the `availability_ingestion` table in `continuumCalendarMySql`.
   - From: `availabilityCore` → `dataAccessCalSer`
   - To: `continuumCalendarMySql`
   - Protocol: JDBC / MySQL

3. **Acknowledge ingest**: `apiResourcesCalSer` returns HTTP 202 Accepted to the caller; compilation is deferred.
   - From: `apiResourcesCalSer`
   - To: caller
   - Protocol: REST

4. **Quartz job fires — compilation trigger**: `continuumCalendarUtility` Quartz scheduler wakes a compilation job based on its configured schedule or a job entry queued during ingest.
   - From: `continuumCalendarUtility` (Quartz scheduler)
   - To: `continuumCalendarUtility` (compilation worker)
   - Protocol: direct / scheduled

5. **Read raw ingestion data**: The compilation worker reads pending raw ingestion records from `continuumCalendarMySql`.
   - From: `continuumCalendarUtility`
   - To: `continuumCalendarMySql`
   - Protocol: JDBC / MySQL

6. **Compile availability windows**: The worker applies availability compilation logic — merging slots, applying open hours and capacity rules — to produce queryable availability records.
   - From: `continuumCalendarUtility` (internal computation)
   - Protocol: internal

7. **Persist compiled availability**: The worker writes compiled `availability_records` back to `continuumCalendarMySql`.
   - From: `continuumCalendarUtility`
   - To: `continuumCalendarMySql`
   - Protocol: JDBC / MySQL

8. **Invalidate Redis cache**: The worker deletes or updates Redis cache keys for the affected service(s) so that subsequent availability queries fetch fresh compiled data.
   - From: `continuumCalendarUtility`
   - To: `continuumCalendarRedis`
   - Protocol: Redis protocol

9. **Publish AvailabilityRecordChanged event**: The utility worker (via scheduled job infrastructure) signals that availability records have changed; `messageBusAdapters` publishes `AvailabilityRecordChanged` to `availabilityEngineEventsBus`.
   - From: `continuumCalendarUtility` → `messageBusAdapters`
   - To: `availabilityEngineEventsBus`
   - Protocol: MBus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL write failure on ingest | Transaction rolled back; HTTP 500 returned to caller | Raw data not stored; caller must retry |
| Compilation job fails mid-run | Quartz marks job as failed; retries on next poll cycle | Stale compiled availability remains until next successful compilation |
| Redis cache invalidation failure | Logged; stale cache entries expire on TTL | Temporary stale availability; corrects on TTL expiry or next compilation |
| MBus publish failure | MBus retry mechanism retries the event publication | Event eventually published; no data loss |

## Sequence Diagram

```
ExternalCaller -> apiResourcesCalSer: POST /v1/services/{id}/ingest_availability { rawAvailability }
apiResourcesCalSer -> availabilityCore: processIngest(serviceId, rawAvailability)
availabilityCore -> dataAccessCalSer: insertIngestionRecord(serviceId, raw)
dataAccessCalSer -> continuumCalendarMySql: INSERT INTO availability_ingestion ...
continuumCalendarMySql --> dataAccessCalSer: stored
apiResourcesCalSer --> ExternalCaller: HTTP 202 Accepted

[Quartz fires compilation job]
continuumCalendarUtility -> continuumCalendarMySql: SELECT pending ingestion records
continuumCalendarMySql --> continuumCalendarUtility: raw availability records
continuumCalendarUtility -> continuumCalendarUtility: compile availability windows
continuumCalendarUtility -> continuumCalendarMySql: UPSERT availability_records (compiled)
continuumCalendarUtility -> continuumCalendarRedis: DEL / invalidate cache keys
continuumCalendarUtility -> messageBusAdapters: publishEvent(AvailabilityRecordChanged)
messageBusAdapters -> availabilityEngineEventsBus: publish AvailabilityRecordChanged
```

## Related

- Architecture dynamic view: `calendarServiceComponents`
- Related flows: [Availability Query and Caching](availability-query-caching.md), [Background Scheduler Jobs](background-scheduler-jobs.md), [Event Consumption Worker](event-consumption-worker.md)
