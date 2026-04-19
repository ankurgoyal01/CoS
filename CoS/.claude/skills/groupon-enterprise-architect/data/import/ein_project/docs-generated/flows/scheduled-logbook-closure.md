---
service: "ein_project"
title: "Scheduled Logbook Closure"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "scheduled-logbook-closure"
flow_type: scheduled
trigger: "Database cron worker (rq-scheduler) on a configured schedule"
participants:
  - "continuumProdcatWebApp"
  - "continuumProdcatWorker"
  - "continuumProdcatRedis"
  - "continuumProdcatPostgres"
  - "jiraCloudSystem_unk_c3d4"
architecture_ref: "dynamic-background-jobs"
---

# Scheduled Logbook Closure

## Summary

The logbook closure flow runs as a scheduled background job in the ProdCat Worker. It queries the PostgreSQL database for deployment change requests that are in a failed, abandoned, or otherwise unresolved state and automatically closes the associated JIRA tickets. This prevents stale open tickets from accumulating in JIRA and ensures the change log accurately reflects terminal deployment outcomes without requiring manual intervention from engineers.

## Trigger

- **Type**: schedule
- **Source**: `einProject_jobScheduler` triggers `dbCronWorker`, which runs the `ticketCloser` job
- **Frequency**: Configured schedule via rq-scheduler (exact interval managed in application configuration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ProdCat Web App | Enqueues the initial async job via Async Task Dispatcher | `continuumProdcatWebApp` |
| Async Task Dispatcher | Writes the job payload to the Redis RQ queue | `asyncTaskDispatcher` |
| Redis | Holds the queued job payload until the worker consumes it | `continuumProdcatRedis` |
| ProdCat Worker | Hosts the scheduler, cron worker, and ticket-closing logic | `continuumProdcatWorker` |
| Job Scheduler | Triggers the dbCronWorker on the configured schedule | `einProject_jobScheduler` |
| Database Cron Worker | Dispatches the ticketCloser job | `dbCronWorker` |
| Ticket Closer | Queries PostgreSQL for stale records and closes JIRA tickets | `ticketCloser` |
| PostgreSQL | Source of stale/failed change request records | `continuumProdcatPostgres` |
| JIRA Cloud | Target for ticket closure API calls | `jiraCloudSystem_unk_c3d4` |

## Steps

1. **Scheduler triggers job**: `einProject_jobScheduler` fires on the configured cron interval and dispatches the logbook closure job to `dbCronWorker`.
   - From: `einProject_jobScheduler`
   - To: `dbCronWorker`
   - Protocol: direct

2. **Enqueue async task**: The web app enqueues the closure job via `asyncTaskDispatcher` to the Redis RQ queue.
   - From: `continuumProdcatWebApp`
   - To: `continuumProdcatRedis`
   - Protocol: TCP/Redis

3. **Worker consumes job**: `rqWorker` pops the job from the Redis queue and begins execution.
   - From: `continuumProdcatWorker`
   - To: `continuumProdcatRedis`
   - Protocol: TCP/Redis

4. **Query stale change records**: `ticketCloser` reads PostgreSQL for change requests that are in a failed, timed-out, or abandoned terminal state and have not had their associated JIRA ticket closed.
   - From: `ticketCloser`
   - To: `continuumProdcatPostgres`
   - Protocol: TCP/SQL

5. **Close JIRA tickets**: For each stale record, `ticketCloser` calls JIRA Cloud API v3 to transition the ticket to a closed or resolved state.
   - From: `ticketCloser`
   - To: JIRA Cloud (`jiraCloudSystem_unk_c3d4`)
   - Protocol: REST

6. **Update deployment records**: `ticketCloser` updates the change record in PostgreSQL to mark the ticket as closed and the closure timestamp.
   - From: `continuumProdcatWorker`
   - To: `continuumProdcatPostgres`
   - Protocol: TCP/SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JIRA is unreachable | Job fails; retried on next scheduled run | Ticket remains open until next successful run |
| PostgreSQL is unreachable | Job fails immediately | No records queried; retried on next scheduled run |
| Redis is unreachable | Job cannot be enqueued or consumed | Scheduled run is skipped until Redis recovers |
| JIRA ticket already closed | API returns error; record skipped | No duplicate closure; record marked as already closed |
| Partial failure mid-batch | Processed records are committed; failed records retried next run | Eventual consistency; no ticket left permanently open |

## Sequence Diagram

```
einProject_jobScheduler -> dbCronWorker: Trigger logbook closure job (scheduled)
continuumProdcatWebApp -> continuumProdcatRedis: Enqueue async job
continuumProdcatWorker -> continuumProdcatRedis: Consume job from queue
ticketCloser -> continuumProdcatPostgres: Query failed/abandoned change records
ticketCloser -> JIRACloud: Close associated tickets (jiraCloudSystem_unk_c3d4)
continuumProdcatWorker -> continuumProdcatPostgres: Update change records (closure timestamp)
```

## Related

- Architecture dynamic view: `dynamic-background-jobs`
- Related flows: [Incident Monitor and Region Lock](incident-monitor-region-lock.md), [Change Request Creation and Approval](change-request-creation-approval.md)
