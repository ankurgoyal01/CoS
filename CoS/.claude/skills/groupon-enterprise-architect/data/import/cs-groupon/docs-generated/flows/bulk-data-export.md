---
service: "cs-groupon"
title: "Bulk Data Export"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "bulk-data-export"
flow_type: batch
trigger: "CS agent requests a bulk data export or a scheduled cron task triggers an export"
participants:
  - "continuumCsWebApp"
  - "continuumCsBackgroundJobs"
  - "continuumCsAppDb"
  - "continuumCsRedisCache"
  - "continuumEmailService"
  - "loggingStack"
  - "metricsStack"
architecture_ref: "dynamic-cs-groupon"
---

# Bulk Data Export

## Summary

When a CS agent needs a large dataset (e.g., all issues for a date range, a user history extract, or a compliance report), cyclops processes the request asynchronously as a background batch job. The Web App enqueues the export job to Resque; a background worker queries `continuumCsAppDb`, assembles the export, and delivers it to the agent via `continuumEmailService` or makes it available for download. This avoids blocking the Web App on large queries.

## Trigger

- **Type**: user-action or schedule
- **Source**: CS agent clicks "Export" in the `continuumCsWebApp` UI, or a scheduled cron task triggers a periodic report export
- **Frequency**: On demand (agent-initiated) or per schedule (cron-triggered)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CS Web App | Accepts export request; enqueues background job; notifies agent of job acceptance | `continuumCsWebApp` |
| CS Background Jobs | Executes the bulk export job; queries DB; assembles output; delivers result | `continuumCsBackgroundJobs` |
| CS App Database | Source of all CS records included in the export | `continuumCsAppDb` |
| CS Redis Cache | Resque job queue backing store; optional progress tracking | `continuumCsRedisCache` |
| Email Service | Delivers export result (download link or attachment) to agent | `continuumEmailService` |
| Logging Stack | Receives job progress and completion logs | `loggingStack` |
| Metrics Stack | Receives export job metrics (duration, record count) | `metricsStack` |

## Steps

1. **Agent requests export**: CS agent submits export request with parameters (date range, filters, format).
   - From: `agent browser`
   - To: `continuumCsWebApp`
   - Protocol: HTTP POST

2. **Session validated and authorization checked**: Web App validates session in Redis and checks CanCan permissions.
   - From: `continuumCsWebApp`
   - To: `continuumCsRedisCache`
   - Protocol: Redis

3. **Export job enqueued**: Web App enqueues an export job payload to the Resque queue in Redis.
   - From: `continuumCsWebApp`
   - To: `continuumCsRedisCache` (Resque queue)
   - Protocol: Redis RPUSH (Resque)

4. **Web App confirms acceptance**: Web App returns a job-accepted response to the agent, informing them the export will be delivered asynchronously.
   - From: `continuumCsWebApp`
   - To: `agent browser`
   - Protocol: HTTP 202 Accepted

5. **Worker dequeues export job**: A `csJobWorkers` Resque worker picks up the export job.
   - From: `continuumCsRedisCache` (Resque queue)
   - To: `continuumCsBackgroundJobs`
   - Protocol: Redis LPOP (Resque)

6. **Worker queries CS database**: Worker executes paginated or batched queries against `continuumCsAppDb` to retrieve the requested dataset.
   - From: `continuumCsBackgroundJobs`
   - To: `continuumCsAppDb`
   - Protocol: ActiveRecord / MySQL

7. **Worker assembles export file**: Worker formats the records into the requested output format (CSV, JSON, etc.) and writes to a temporary location.
   - From: `continuumCsBackgroundJobs`
   - To: local file / temp storage
   - Protocol: File I/O

8. **Worker logs progress**: Job progress logged to `loggingStack`; duration and record count published to `metricsStack`.
   - From: `continuumCsBackgroundJobs`
   - To: `loggingStack`, `metricsStack`
   - Protocol: Internal

9. **Worker delivers export**: Worker sends the export file or a download link to the requesting agent via Email Service.
   - From: `continuumCsBackgroundJobs`
   - To: `continuumEmailService`
   - Protocol: REST

10. **Agent receives export**: Agent receives an email with the export file or link and downloads the dataset.
    - From: `continuumEmailService`
    - To: `agent email client`
    - Protocol: Email (SMTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DB query times out | Resque retries job with backoff | Export delayed; eventually completes or lands in `:failed` queue |
| Email delivery fails | Resque retries email send step | Agent not notified; manual check of `:failed` queue required |
| Export job permanently fails | Job moves to Resque `:failed` queue; error logged | GSO Engineering must manually inspect and replay; agent must resubmit request |
| Large dataset causes memory pressure | Job processes in paginated batches | Memory usage bounded; export takes longer but completes |

## Sequence Diagram

```
Agent -> continuumCsWebApp: POST /exports (export parameters)
continuumCsWebApp -> continuumCsRedisCache: Validate session
continuumCsWebApp -> continuumCsRedisCache: Enqueue export job (Resque)
continuumCsWebApp --> Agent: 202 Accepted — export in progress
continuumCsRedisCache -> continuumCsBackgroundJobs: Dequeue export job
continuumCsBackgroundJobs -> continuumCsAppDb: Paginated batch queries
continuumCsBackgroundJobs -> continuumCsBackgroundJobs: Assemble export file
continuumCsBackgroundJobs -> loggingStack: Log progress and completion
continuumCsBackgroundJobs -> metricsStack: Record duration and record count
continuumCsBackgroundJobs -> continuumEmailService: Deliver export to agent
continuumEmailService --> agent email client: Email with export file/link
```

## Related

- Architecture dynamic view: `dynamic-cs-groupon`
- Related flows: [Scheduled Cron Jobs](scheduled-cron-jobs.md), [Background Job Retry](background-job-retry.md)
- Runbook guidance: [Runbook](../runbook.md)
