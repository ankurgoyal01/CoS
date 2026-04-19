---
service: "bots"
title: "Calendar Synchronization Background Job"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "calendar-synchronization-background-job"
flow_type: scheduled
trigger: "Quartz scheduler fires the calendar import/export job at a configured interval"
participants:
  - "botsWorkerSchedulersComponent"
  - "botsWorkerJobServicesComponent"
  - "botsApiPersistenceComponent"
  - "botsApiIntegrationClientsComponent"
  - "continuumBotsMysql"
  - "googleOAuth"
  - "googleCalendar"
architecture_ref: "dynamic-bots-booking-request-flow"
---

# Calendar Synchronization Background Job

## Summary

BOTS Worker runs a scheduled Quartz job to synchronize merchant calendars with Google Calendar. For each merchant with an active Google Calendar integration, the job authenticates via Google OAuth, fetches external calendar events (import), writes BOTS bookings back as Google Calendar events (export), and updates the sync state in `continuumBotsMysql`. This keeps merchant calendar availability accurate and reflects BOTS bookings in the merchant's native calendar.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler within `continuumBotsWorker` (`botsWorkerSchedulersComponent`)
- **Frequency**: Periodic interval (specific cron expression managed in Quartz/JTier configuration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Schedulers | Fires the calendar sync job on schedule | `botsWorkerSchedulersComponent` |
| Job Services | Orchestrates the import/export logic per merchant | `botsWorkerJobServicesComponent` |
| Persistence Access | Reads merchant calendar config and sync state; writes updated sync state | `botsApiPersistenceComponent` |
| Integration Clients | Calls Google OAuth and Google Calendar API | `botsApiIntegrationClientsComponent` |
| BOTS MySQL | Stores merchant calendar sync tokens and state | `continuumBotsMysql` |
| Google OAuth | Provides OAuth 2.0 tokens for merchant calendar access | `googleOAuth` |
| Google Calendar API | Source and target for calendar event synchronization | `googleCalendar` |

## Steps

1. **Fire scheduled job**: Quartz scheduler triggers the calendar sync job.
   - From: `botsWorkerSchedulersComponent`
   - To: `botsWorkerJobServicesComponent`
   - Protocol: Direct (Quartz job dispatch)

2. **Load merchants with active calendar sync**: Job services query `continuumBotsMysql` for merchants with Google Calendar integration enabled.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

3. **Authenticate with Google OAuth**: For each merchant, job services obtain a valid OAuth 2.0 token.
   - From: `botsApiIntegrationClientsComponent`
   - To: `googleOAuth`
   - Protocol: OAuth 2.0 (google-api-client 1.25.0)

4. **Import external calendar events**: Job services fetch new/updated events from the merchant's Google Calendar using the stored sync token.
   - From: `botsApiIntegrationClientsComponent`
   - To: `googleCalendar`
   - Protocol: REST (Google Calendar API v3)

5. **Reconcile imported events**: Job services compare imported calendar events with BOTS availability windows and create or update blocking entries in `continuumBotsMysql`.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

6. **Export BOTS bookings to Google Calendar**: Job services write new BOTS booking records as Google Calendar events for the merchant.
   - From: `botsApiIntegrationClientsComponent`
   - To: `googleCalendar`
   - Protocol: REST (Google Calendar API v3, ical4j 3.0.20)

7. **Update sync state**: Job services store the updated Google Calendar sync token and last-sync timestamp in `continuumBotsMysql`.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Google OAuth token expired | Attempt token refresh; if re-auth required, log error and skip merchant | Merchant sync skipped; re-authentication needed |
| Google Calendar API rate limit exceeded | Back-off and retry on next job run | Sync delayed by one job interval |
| DB failure reading merchant list | Log error; job exits without processing | All merchant syncs deferred to next run |
| DB failure writing sync state | Log error; sync token not updated | Next run may re-process events already synced (idempotent where possible) |
| Individual merchant sync failure | Log error; continue processing remaining merchants | Failing merchant sync deferred; others complete normally |

## Sequence Diagram

```
botsWorkerSchedulersComponent -> botsWorkerJobServicesComponent: Fire calendar sync job
botsWorkerJobServicesComponent -> botsApiPersistenceComponent: Load merchants with calendar sync enabled
botsApiPersistenceComponent -> continuumBotsMysql: SELECT calendar sync configs
continuumBotsMysql --> botsApiPersistenceComponent: Merchant calendar records
botsWorkerJobServicesComponent -> botsApiIntegrationClientsComponent: Authenticate per merchant
botsApiIntegrationClientsComponent -> googleOAuth: Get/refresh OAuth token
googleOAuth --> botsApiIntegrationClientsComponent: Access token
botsWorkerJobServicesComponent -> botsApiIntegrationClientsComponent: Import external events
botsApiIntegrationClientsComponent -> googleCalendar: GET calendar events (sync token)
googleCalendar --> botsApiIntegrationClientsComponent: Calendar events
botsWorkerJobServicesComponent -> botsApiPersistenceComponent: Reconcile and write blocking entries
botsApiPersistenceComponent -> continuumBotsMysql: UPSERT availability blocks
botsWorkerJobServicesComponent -> botsApiIntegrationClientsComponent: Export BOTS bookings
botsApiIntegrationClientsComponent -> googleCalendar: POST/PATCH booking events
googleCalendar --> botsApiIntegrationClientsComponent: Events updated
botsWorkerJobServicesComponent -> botsApiPersistenceComponent: Update sync token and last-sync time
botsApiPersistenceComponent -> continuumBotsMysql: UPDATE calendar sync state
```

## Related

- Architecture dynamic view: `dynamic-bots-booking-request-flow`
- Related flows: [Booking Availability Query](booking-availability-query.md), [Deal Onboarding and Initialization](deal-onboarding-and-initialization.md)
