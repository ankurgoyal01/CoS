---
service: "glive-gia"
title: "Ticketmaster Event Import"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "ticketmaster-event-import"
flow_type: scheduled
trigger: "Resque-scheduler cron job fires on configured schedule"
participants:
  - "continuumGliveGiaWorker"
  - "continuumGliveGiaRedisCache"
  - "continuumGliveGiaMysqlDatabase"
architecture_ref: "dynamic-glive-gia-tm-import"
---

# Ticketmaster Event Import

## Summary

GIA runs a scheduled background job that imports live event listings and availability data from the Ticketmaster API for deals that are configured with Ticketmaster settings. The job iterates over active deals with Ticketmaster configurations, fetches current event data from the Ticketmaster API using per-deal credentials, and updates or creates the corresponding event records in GIA's MySQL database. This ensures that GIA's event inventory reflects the latest data from Ticketmaster without manual admin intervention.

## Trigger

- **Type**: schedule
- **Source**: resque-scheduler fires the import job on a configured cron schedule (defined in `config/schedule.rb`)
- **Frequency**: Periodic (exact cron expression configured in deployment; typically hourly or daily)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GIA Redis (Scheduler) | Triggers the scheduled job and holds it in the Resque queue | `continuumGliveGiaRedisCache` |
| GIA Background Worker | Executes the import job; calls Ticketmaster API; writes results to MySQL | `continuumGliveGiaWorker` |
| Ticketmaster API | External source of event listings and availability | External |
| GIA MySQL Database | Stores fetched event data; source of per-deal Ticketmaster settings | `continuumGliveGiaMysqlDatabase` |

## Steps

1. **Scheduler fires import job**: resque-scheduler enqueues the Ticketmaster import job onto the Resque queue in Redis per the cron schedule
   - From: resque-scheduler (within `continuumGliveGiaRedisCache`)
   - To: `continuumGliveGiaRedisCache` (Resque queue)
   - Protocol: Resque / Redis

2. **Worker picks up job**: `resqueWorkers_GliGia` polls the Redis queue and dequeues the import job
   - From: `continuumGliveGiaWorker` (`resqueWorkers_GliGia`)
   - To: `continuumGliveGiaRedisCache`
   - Protocol: Resque / Redis

3. **Load active deals with TM settings**: `jobServices_GliGia` queries MySQL via `workerDomainModels` to retrieve all active deals that have Ticketmaster settings configured
   - From: `continuumGliveGiaWorker` (`jobServices_GliGia` -> `workerDomainModels`)
   - To: `continuumGliveGiaMysqlDatabase`
   - Protocol: ActiveRecord / MySQL

4. **Fetch events from Ticketmaster API**: For each deal, `workerRemoteClients_GliGia` calls the Ticketmaster API using the per-deal API credentials from `ticketmaster_settings`
   - From: `continuumGliveGiaWorker` (`workerRepositories_GliGia` -> `workerRemoteClients_GliGia`)
   - To: Ticketmaster API
   - Protocol: REST (HTTPS)

5. **Map Ticketmaster response**: `workerMappers` translate Ticketmaster API event payload into GIA event domain attributes
   - From: `workerRepositories_GliGia`
   - To: `workerMappers`
   - Protocol: Direct (in-process)

6. **Upsert event records**: `jobServices_GliGia` creates or updates event records in MySQL via `workerDomainModels` using the mapped data
   - From: `continuumGliveGiaWorker` (`jobServices_GliGia` -> `workerDomainModels`)
   - To: `continuumGliveGiaMysqlDatabase`
   - Protocol: ActiveRecord / MySQL

7. **Repeat for all configured deals**: Steps 4-6 repeat for each deal with a Ticketmaster configuration

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Ticketmaster API returns HTTP error | `workerRemoteClients_GliGia` raises exception; Resque retries the job | Events for that deal not updated; retried on next Resque retry cycle |
| Per-deal API credentials invalid | HTTP 401/403 from TM API; job logs error; continues processing other deals | Events for that deal not updated; alert if error rate is high |
| MySQL write failure | ActiveRecord exception; job fails for that record; Resque retries | Partial import may result; retried on next cycle |
| Ticketmaster API timeout | Typhoeus raises timeout exception; Resque retries | Import delayed until retry |

## Sequence Diagram

```
resque-scheduler -> GIA Redis: RPUSH import_ticketmaster_events job
GIA Background Worker -> GIA Redis: LPOP job
GIA Background Worker -> GIA MySQL Database: SELECT deals with ticketmaster_settings
GIA MySQL Database --> GIA Background Worker: active TM-configured deals
loop for each deal
  GIA Background Worker -> Ticketmaster API: GET /events?id=<tm_event_id>
  Ticketmaster API --> GIA Background Worker: event listing data
  GIA Background Worker -> GIA MySQL Database: UPSERT events (create or update)
end
```

## Related

- Architecture dynamic view: `dynamic-glive-gia-tm-import`
- Related flows: [Event Management and Bulk Updates](event-management-and-bulk-updates.md), [Deal Creation from DMAPI](deal-creation-from-dmapi.md)
