---
service: "ARQWeb"
title: "Scheduled User and Service Sync"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-user-service-sync"
flow_type: scheduled
trigger: "ARQ Worker cron schedule fires for user sync and service chain sync jobs"
participants:
  - "continuumArqWorker"
  - "continuumArqPostgres"
  - "workday"
  - "servicePortal"
  - "elasticApm"
architecture_ref: "components-continuum-arq-worker"
---

# Scheduled User and Service Sync

## Summary

The ARQ Worker periodically synchronizes two key data sets into the ARQ PostgreSQL database to keep approval routing and service ownership data current. A Workday sync job pulls updated employee profiles, reporting manager hierarchies, and employment status changes. A Service Portal sync job pulls updated service chain definitions, service classifications, and ownership assignments. Both jobs are scheduled by the `arqWorkerCronLoop` and run independently on their own schedule.

## Trigger

- **Type**: schedule
- **Source**: `arqWorkerCronLoop` — fires scheduled sync jobs based on cron definitions stored in the job queue
- **Frequency**: Periodic (exact intervals not discoverable from architecture model; typically daily or hourly for user sync, daily for service sync)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ARQ Worker | Runs the cron loop, dispatches sync job handlers, applies data updates | `continuumArqWorker` |
| ARQ PostgreSQL | Stores employee and service data; provides job schedule state | `continuumArqPostgres` |
| Workday | Source of truth for employee profiles and manager hierarchy | `workday` |
| Service Portal | Source of truth for service chain and ownership metadata | `servicePortal` |
| Elastic APM | Receives sync job telemetry and error traces | `elasticApm` |

## Steps

### Workday User Sync

1. **Cron loop fires Workday sync job**: `arqWorkerCronLoop` evaluates job schedule and dispatches the user sync job handler.
   - From: `arqWorkerCronLoop`
   - To: `arqWorkerJobHandlers`
   - Protocol: direct (in-process)

2. **Claims sync job**: Marks the sync job as `running` in PostgreSQL to prevent duplicate concurrent runs.
   - From: `arqWorkerPersistence`
   - To: `continuumArqPostgres`
   - Protocol: SQL/TCP

3. **Fetches employee data from Workday**: Calls the Workday API to retrieve updated employee profiles, manager reporting chains, and termination/leave statuses.
   - From: `arqWorkerExternalAdapters`
   - To: `workday`
   - Protocol: HTTPS

4. **Updates employee records in PostgreSQL**: Writes updated employee and manager hierarchy data to the ARQ database, used for approval routing and request validation.
   - From: `arqWorkerPersistence`
   - To: `continuumArqPostgres`
   - Protocol: SQL/TCP

5. **Schedules next sync job**: Writes the next Workday sync job to the queue with the appropriate `scheduled_at` time.
   - From: `arqWorkerPersistence`
   - To: `continuumArqPostgres`
   - Protocol: SQL/TCP

### Service Portal Sync

6. **Cron loop fires Service Portal sync job**: `arqWorkerCronLoop` dispatches the service chain sync handler.
   - From: `arqWorkerCronLoop`
   - To: `arqWorkerJobHandlers`
   - Protocol: direct (in-process)

7. **Fetches service data from Service Portal**: Calls the Service Portal API to retrieve current service chain definitions, classification tags, and ownership assignments.
   - From: `arqWorkerExternalAdapters`
   - To: `servicePortal`
   - Protocol: HTTPS/JSON

8. **Updates service metadata in PostgreSQL**: Writes updated service ownership and classification data to the ARQ database for use in request routing and approvals.
   - From: `arqWorkerPersistence`
   - To: `continuumArqPostgres`
   - Protocol: SQL/TCP

9. **Publishes sync telemetry**: Reports sync job duration and any errors to Elastic APM.
   - From: `continuumArqWorker`
   - To: `elasticApm`
   - Protocol: APM agent

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Workday API unavailable | Sync job retried on next cron cycle | Approval routing uses stale employee data until next successful sync |
| Service Portal API unavailable | Sync job retried on next cron cycle | Service ownership data may be stale; requests still processed |
| Partial data fetch | Sync applies only successfully fetched records; job retried | Incremental update applied; no data loss |
| Maximum retries exceeded | Job marked as `failed`; alert triggered | Manual intervention required; stale data persists |
| Terminated employee detected | Employee record marked inactive in ARQ database | Pending requests involving terminated employees may be auto-rejected or escalated |

## Sequence Diagram

```
ARQWorker.CronLoop -> ARQPostgres: SELECT due sync jobs
ARQPostgres --> ARQWorker.CronLoop: Workday sync job + Service Portal sync job
ARQWorker.CronLoop -> ARQWorker.JobHandlers: Dispatch Workday sync
ARQWorker.ExternalAdapters -> Workday: GET employee profiles and manager chains
Workday --> ARQWorker.ExternalAdapters: Employee data
ARQWorker.Persistence -> ARQPostgres: UPSERT employee and manager records
ARQWorker.CronLoop -> ARQWorker.JobHandlers: Dispatch Service Portal sync
ARQWorker.ExternalAdapters -> ServicePortal: GET service chains and ownership
ServicePortal --> ARQWorker.ExternalAdapters: Service metadata
ARQWorker.Persistence -> ARQPostgres: UPSERT service chain and ownership records
ARQWorker -> ElasticAPM: Report sync telemetry
```

## Related

- Architecture dynamic view: `components-continuum-arq-worker`
- Related flows: [Access Request Submission](access-request-submission.md), [Employee Onboarding](employee-onboarding.md)
