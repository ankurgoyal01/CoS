---
service: "service-portal"
title: "Service Inactivity Report Generation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "service-inactivity-report-generation"
flow_type: scheduled
trigger: "Sidekiq-Cron schedule — recurring inactivity report job"
participants:
  - "continuumServicePortalWorker"
  - "continuumServicePortalWeb"
  - "continuumServicePortalDb"
  - "continuumServicePortalRedis"
---

# Service Inactivity Report Generation

## Summary

On a recurring cron schedule, the Sidekiq worker identifies services that have had no recent activity (no metadata updates, no check result changes, no GitHub sync events) beyond a configured inactivity threshold. It writes inactivity report data to MySQL. The generated report is subsequently accessible via the `GET /reports/*` endpoints on the web process, enabling engineering leadership to identify and action stale or abandoned services.

## Trigger

- **Type**: schedule
- **Source**: sidekiq-cron schedule defined in `config/sidekiq.yml`
- **Frequency**: Recurring on a configured cron expression (exact schedule defined in `config/sidekiq.yml`; typically daily or weekly)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| sidekiq-cron | Enqueues the inactivity report job at the scheduled interval | `continuumServicePortalRedis` |
| Sidekiq Worker | Dequeues job; evaluates service activity; writes report data | `continuumServicePortalWorker` |
| MySQL Database | Source of service records and activity timestamps; target for report data | `continuumServicePortalDb` |
| Rails Web App | Serves the generated inactivity report via `/reports/*` | `continuumServicePortalWeb` |

## Steps

1. **Enqueue inactivity report job**: sidekiq-cron fires at the configured interval and enqueues the inactivity report job.
   - From: sidekiq-cron (running in `continuumServicePortalWorker`)
   - To: `continuumServicePortalRedis`
   - Protocol: Redis protocol

2. **Dequeue job**: Sidekiq worker thread dequeues the inactivity report job.
   - From: `continuumServicePortalRedis`
   - To: `continuumServicePortalWorker`
   - Protocol: Redis protocol

3. **Fetch all service records with activity timestamps**: Worker queries `continuumServicePortalDb` for all registered services, retrieving their last-updated timestamps, last check result timestamps, and last GitHub sync timestamps.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

4. **Identify inactive services**: Worker evaluates each service against the inactivity threshold. A service is considered inactive if no activity has occurred across all tracked dimensions within the threshold period.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalWorker` (internal logic)
   - Protocol: direct

5. **Write inactivity report data**: Worker persists the list of inactive services and their last-activity timestamps to the report storage tables in `continuumServicePortalDb`.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

6. **Report available via API**: On subsequent consumer requests, `GET /reports/*` on the web process reads the generated report data from `continuumServicePortalDb` and returns it.
   - From: Consumer (engineering leadership / tooling)
   - To: `continuumServicePortalWeb`
   - Protocol: HTTPS REST

7. **Web app serves report**: Web app queries `continuumServicePortalDb` for the most recent inactivity report and returns it as JSON or HTML.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

8. **Return report to consumer**: HTTP 200 response with report data returned to consumer.
   - From: `continuumServicePortalWeb`
   - To: Consumer
   - Protocol: HTTPS REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL connectivity failure during report generation | Sidekiq job raises exception | Job retried with backoff; report generation delayed |
| No services meet inactivity threshold | Empty result set | Report written with zero inactive services; no alert |
| MySQL connectivity failure during report read | ActiveRecord exception raised in web process | HTTP 500; error logged |
| Previous report not yet generated | No report data in DB | HTTP 404 or empty report response |

## Sequence Diagram

```
sidekiq-cron -> continuumServicePortalRedis: enqueue InactivityReportJob
continuumServicePortalRedis -> continuumServicePortalWorker: dequeue InactivityReportJob
continuumServicePortalWorker -> continuumServicePortalDb: SELECT services + activity timestamps
continuumServicePortalDb --> continuumServicePortalWorker: service activity data
continuumServicePortalWorker -> continuumServicePortalWorker: evaluate inactivity thresholds
continuumServicePortalWorker -> continuumServicePortalDb: INSERT/UPDATE inactivity report records
continuumServicePortalDb --> continuumServicePortalWorker: report data persisted
Consumer -> continuumServicePortalWeb: GET /reports/inactivity
continuumServicePortalWeb -> continuumServicePortalDb: SELECT inactivity report data
continuumServicePortalDb --> continuumServicePortalWeb: report records
continuumServicePortalWeb --> Consumer: 200 OK (inactivity report JSON/HTML)
```

## Related

- Architecture dynamic view: `dynamic-inactivity-report`
- Related flows: [Scheduled Service Checks Execution](scheduled-service-checks-execution.md), [Cost Tracking and Alerting](cost-tracking-and-alerting.md)
