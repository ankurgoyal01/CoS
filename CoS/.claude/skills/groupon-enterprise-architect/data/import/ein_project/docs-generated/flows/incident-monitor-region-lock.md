---
service: "ein_project"
title: "Incident Monitor and Region Lock"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "incident-monitor-region-lock"
flow_type: scheduled
trigger: "Database cron worker (rq-scheduler) on a configured schedule"
participants:
  - "continuumProdcatWorker"
  - "continuumProdcatRedis"
  - "continuumProdcatPostgres"
  - "jsmAlertsSystem_unk_d4e5"
architecture_ref: "dynamic-background-jobs"
---

# Incident Monitor and Region Lock

## Summary

The incident monitor flow runs as a scheduled background job in the ProdCat Worker. It polls Jira Service Management (JSM) and PagerDuty for active incidents associated with Groupon's deployment regions. When an active incident is detected for a region, the job applies a region lock in the PostgreSQL database, which causes all subsequent change request validations for that region to be rejected. When incidents are resolved, the job lifts the lock. This provides automatic, near-real-time enforcement of deployment freezes during live incidents without requiring manual operator action.

## Trigger

- **Type**: schedule
- **Source**: `einProject_jobScheduler` triggers `dbCronWorker`, which runs the `incidentMonitor` job
- **Frequency**: Configured schedule via rq-scheduler (exact interval managed in application configuration; expected to run frequently — e.g., every few minutes — to minimize lock propagation delay)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ProdCat Worker | Hosts the job scheduler, cron worker, and incident monitor logic | `continuumProdcatWorker` |
| Job Scheduler | Triggers the dbCronWorker on the configured schedule | `einProject_jobScheduler` |
| Database Cron Worker | Dispatches the incidentMonitor job | `dbCronWorker` |
| Incident Monitor | Polls external incident sources and applies/lifts region locks | `incidentMonitor` |
| JSM Alerts Client | Queries JSM for active alerts scoped to deployment regions | `jsmAlertsClient` |
| PostgreSQL | Source of region configuration; target for lock state writes | `continuumProdcatPostgres` |
| Redis | Job queue coordination between scheduler and worker | `continuumProdcatRedis` |
| JSM | External incident alert source | `jsmAlertsSystem_unk_d4e5` |

## Steps

1. **Scheduler triggers job**: `einProject_jobScheduler` fires on the configured interval and dispatches the incident monitor job to `dbCronWorker`.
   - From: `einProject_jobScheduler`
   - To: `dbCronWorker`
   - Protocol: direct

2. **Worker consumes job**: `rqWorker` (or `dbCronWorker` directly) picks up the job.
   - From: `continuumProdcatWorker`
   - To: `continuumProdcatRedis`
   - Protocol: TCP/Redis

3. **Load region configuration**: `incidentMonitor` reads the list of configured deployment regions from PostgreSQL.
   - From: `incidentMonitor`
   - To: `continuumProdcatPostgres`
   - Protocol: TCP/SQL

4. **Poll JSM for active incidents**: For each region, `incidentMonitor` calls JSM to check for active alerts associated with that region.
   - From: `incidentMonitor`
   - To: JSM (`jsmAlertsSystem_unk_d4e5`)
   - Protocol: REST

5. **Poll PagerDuty for active incidents**: `incidentMonitor` also queries PagerDuty via `pdpyras` to cross-reference active incidents for each region.
   - From: `incidentMonitor`
   - To: PagerDuty (external, no stub ID in current model)
   - Protocol: REST

6. **Apply region lock** (if incident detected): For each region with an active incident, `incidentMonitor` writes or updates a region lock record in PostgreSQL.
   - From: `incidentMonitor`
   - To: `continuumProdcatPostgres`
   - Protocol: TCP/SQL

7. **Lift region lock** (if incident resolved): For each region where all incidents are resolved, `incidentMonitor` clears the region lock record in PostgreSQL.
   - From: `incidentMonitor`
   - To: `continuumProdcatPostgres`
   - Protocol: TCP/SQL

8. **Lock state consumed by validation**: On the next inbound change request validation (a separate flow), the updated region lock state is read from PostgreSQL (or Redis cache) and applied to the policy check.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JSM is unreachable | Last known lock state preserved | Region remains in its current lock state until JSM recovers |
| PagerDuty is unreachable | Last known lock state preserved | Region remains in its current lock state until PagerDuty recovers |
| PostgreSQL is unreachable | Job fails; retried on next scheduled run | Lock state not updated; existing locks remain |
| Redis is unreachable | Job enqueue/consume fails; run skipped | No lock state update for that cycle |
| Stale lock after incident resolution | Next successful poll clears the lock | Lock is eventually lifted; window of over-restriction possible |

## Sequence Diagram

```
einProject_jobScheduler -> dbCronWorker: Trigger incident monitor job (scheduled)
continuumProdcatWorker -> continuumProdcatRedis: Consume job from queue
incidentMonitor -> continuumProdcatPostgres: Load region configuration
incidentMonitor -> JSM: Poll active incidents per region (jsmAlertsSystem_unk_d4e5)
incidentMonitor -> PagerDuty: Poll active incidents per region
incidentMonitor -> continuumProdcatPostgres: Apply region lock (incident active)
incidentMonitor -> continuumProdcatPostgres: Lift region lock (incident resolved)
```

## Related

- Architecture dynamic view: `dynamic-background-jobs`
- Related flows: [Change Request Creation and Approval](change-request-creation-approval.md), [Scheduled Logbook Closure](scheduled-logbook-closure.md)
