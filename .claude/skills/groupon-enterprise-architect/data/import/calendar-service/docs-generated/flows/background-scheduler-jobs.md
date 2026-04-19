---
service: "calendar-service"
title: "Background Scheduler Jobs"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "background-scheduler-jobs"
flow_type: scheduled
trigger: "Quartz scheduler in continuumCalendarUtility fires on configured cron intervals"
participants:
  - "continuumCalendarUtility"
  - "continuumCalendarPostgres"
  - "continuumCalendarMySql"
  - "continuumCalendarRedis"
  - "continuumEpodsService"
architecture_ref: "calendarServiceComponents"
---

# Background Scheduler Jobs

## Summary

The `continuumCalendarUtility` hosts run a Quartz scheduler (`jtier-quartz-bundle`) that executes three categories of background jobs independently of the API request path: EPODS booking synchronization (confirms or cancels pending EPODS reservations), booking cleanup (removes expired or orphaned booking records from Postgres), and redemption reconciliation (aligns booking redemption state with external system records). These jobs operate directly against `continuumCalendarPostgres`, `continuumCalendarMySql`, and `continuumCalendarRedis`, and call `continuumEpodsService` via `calendarService_externalClients`.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler running inside `continuumCalendarUtility`; jobs are configured via the Dropwizard YAML config file
- **Frequency**: Per job — exact cron intervals are not declared in the architecture DSL; expected to run every few minutes for EPODS sync and daily/hourly for cleanup and reconciliation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Calendar Service Utility Hosts | Hosts the Quartz scheduler and executes all background jobs | `continuumCalendarUtility` |
| Schedulers and Background Jobs | Quartz job implementations for EPODS sync, cleanup, and redemption | `calendarService_schedulerJobs` |
| External Client Adapters | Calls EPODS for booking status checks and updates | `calendarService_externalClients` |
| Calendar Service Postgres DaaS | Source and target for booking and job state | `continuumCalendarPostgres` |
| Availability Engine MySQL DaaS | Source for availability compilation data used by background jobs | `continuumCalendarMySql` |
| Calendar Service Redis Cache | Invalidated after booking state changes | `continuumCalendarRedis` |
| EPODS Service | Receives status check and update calls from the sync job | `continuumEpodsService` |

## Steps

### EPODS Booking Sync Job

1. **Job fires**: Quartz wakes the EPODS sync job in `continuumCalendarUtility`.
   - From: Quartz scheduler
   - To: `calendarService_schedulerJobs`
   - Protocol: scheduled / direct

2. **Query pending sync bookings**: The job reads bookings in `pending_sync` or `epods_pending` state from `continuumCalendarPostgres`.
   - From: `calendarService_schedulerJobs`
   - To: `continuumCalendarPostgres`
   - Protocol: JDBC / PostgreSQL

3. **Check EPODS booking status**: For each pending booking, calls `calendarService_externalClients` to query the current EPODS booking status.
   - From: `calendarService_schedulerJobs` → `calendarService_externalClients`
   - To: `continuumEpodsService`
   - Protocol: REST

4. **Update booking state**: Based on the EPODS response, updates the booking status in `continuumCalendarPostgres` (confirmed, declined, or retry).
   - From: `calendarService_schedulerJobs`
   - To: `continuumCalendarPostgres`
   - Protocol: JDBC / PostgreSQL

5. **Invalidate cache entries**: Invalidates Redis cache keys for affected bookings and their availability slots.
   - From: `continuumCalendarUtility`
   - To: `continuumCalendarRedis`
   - Protocol: Redis protocol

6. **Publish events**: `calendarService_schedulerJobs` signals `messageBusAdapters` (in the API hosts) to publish `AvailabilityRecordChanged` for updated bookings.
   - From: `calendarService_schedulerJobs` → `messageBusAdapters`
   - To: `availabilityEngineEventsBus`
   - Protocol: MBus

### Booking Cleanup Job

1. **Job fires**: Quartz wakes the cleanup job on its configured schedule.
   - From: Quartz scheduler
   - To: `calendarService_schedulerJobs`
   - Protocol: scheduled / direct

2. **Identify expired bookings**: Queries `continuumCalendarPostgres` for bookings past expiry thresholds with terminal-eligible states.
   - From: `calendarService_schedulerJobs`
   - To: `continuumCalendarPostgres`
   - Protocol: JDBC / PostgreSQL

3. **Delete or archive expired records**: Removes or moves expired booking records in `continuumCalendarPostgres`; releases associated unit slot capacity.
   - From: `calendarService_schedulerJobs`
   - To: `continuumCalendarPostgres`
   - Protocol: JDBC / PostgreSQL

4. **Invalidate stale cache entries**: Cleans up Redis keys for removed bookings.
   - From: `continuumCalendarUtility`
   - To: `continuumCalendarRedis`
   - Protocol: Redis protocol

### Redemption Reconciliation Job

1. **Job fires**: Quartz wakes the redemption reconciliation job on its configured schedule.
   - From: Quartz scheduler
   - To: `calendarService_schedulerJobs`
   - Protocol: scheduled / direct

2. **Query bookings pending redemption reconciliation**: Reads bookings requiring redemption state alignment from `continuumCalendarPostgres`.
   - From: `calendarService_schedulerJobs`
   - To: `continuumCalendarPostgres`
   - Protocol: JDBC / PostgreSQL

3. **Reconcile with external state**: Calls `calendarService_externalClients` to verify redemption status with EPODS or other systems as needed.
   - From: `calendarService_schedulerJobs` → `calendarService_externalClients`
   - To: `continuumEpodsService`
   - Protocol: REST

4. **Update redemption state**: Writes reconciled redemption status back to `continuumCalendarPostgres`.
   - From: `calendarService_schedulerJobs`
   - To: `continuumCalendarPostgres`
   - Protocol: JDBC / PostgreSQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| EPODS unavailable during sync | Circuit breaker via `jtier-resilience4j` trips; job marks bookings for retry; Quartz re-queues on next poll | Sync delayed; bookings remain in pending state until EPODS recovers |
| Postgres write failure | Job execution fails; Quartz records failure and retries on next trigger | Booking state unchanged; retry on next Quartz cycle |
| Redis cache invalidation failure | Logged; stale cache expires on TTL | Temporary stale data; no functional impact |
| Job misfire (Quartz missed schedule) | Quartz misfire instruction configured to re-fire immediately or skip | Depends on Quartz misfire policy; catch-up or skip |

## Sequence Diagram

```
[Quartz timer]
QuartzScheduler -> calendarService_schedulerJobs: fire EPODS sync job
calendarService_schedulerJobs -> continuumCalendarPostgres: SELECT bookings WHERE status='pending_sync'
continuumCalendarPostgres --> calendarService_schedulerJobs: pending bookings list
loop for each pending booking
  calendarService_schedulerJobs -> calendarService_externalClients: checkEpodsStatus(bookingRef)
  calendarService_externalClients -> continuumEpodsService: GET /bookings/{ref}
  continuumEpodsService --> calendarService_externalClients: EPODS status
  calendarService_schedulerJobs -> continuumCalendarPostgres: UPDATE booking status
end
continuumCalendarUtility -> continuumCalendarRedis: DEL cache keys
```

## Related

- Architecture dynamic view: `dynamic-calendarBookingAndSyncFlow`
- Related flows: [Booking Creation and EPODS Sync](booking-creation-epods-sync.md), [Availability Ingestion and Compilation](availability-ingestion-compilation.md)
