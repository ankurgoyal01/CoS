---
service: "garvis"
title: "Background Job Scheduling"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "background-job-scheduling"
flow_type: scheduled
trigger: "RQ Scheduler timer or explicit enqueue from bot/web handler"
participants:
  - "continuumJarvisWebApp"
  - "continuumJarvisBot"
  - "continuumJarvisWorker"
  - "continuumJarvisRedis"
  - "continuumJarvisPostgres"
  - "googleChatApi"
architecture_ref: "dynamic-backgroundJobScheduling"
---

# Background Job Scheduling

## Summary

The Background Job Scheduling flow covers how Garvis defers and schedules work that should not block the synchronous Google Chat response path or the webhook handler. Jobs are enqueued onto Redis RQ queues by the bot or web app, and executed asynchronously by `continuumJarvisWorker`. Recurring tasks (e.g., periodic on-call rotation reminders, scheduled status check notifications, report generation) are managed by `workerScheduler` (RQ Scheduler), which enqueues jobs at configured intervals.

## Trigger

- **Type**: schedule (recurring via RQ Scheduler) or asynchronous (explicit enqueue from bot command handler or web controller)
- **Source**: `workerScheduler` fires on configured interval, OR `continuumJarvisBot` / `continuumJarvisWebApp` enqueues a job explicitly in response to a user action
- **Frequency**: Varies by job type — per-request for ad-hoc jobs; hourly/daily/weekly for scheduled recurring jobs

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Jarvis Web App | Enqueues jobs triggered by webhook events (e.g., JIRA webhook) | `continuumJarvisWebApp` |
| Jarvis Bot | Enqueues jobs triggered by Google Chat commands | `continuumJarvisBot` |
| Jarvis Redis | Holds RQ job queues and RQ Scheduler entries | `continuumJarvisRedis` |
| Jarvis Worker (RQ Worker) | Dequeues and executes jobs | `continuumJarvisWorker` |
| Jarvis Worker (RQ Scheduler) | Manages recurring job schedules and enqueues jobs at configured times | `continuumJarvisWorker` |
| Jarvis Postgres | Stores job results and any persistent state updated by job execution | `continuumJarvisPostgres` |
| Google Chat API | Receives notifications sent by executed jobs | `googleChatApi` |

## Steps

### Ad-hoc Job Enqueue (triggered by bot or web)

1. **Receives triggering event**: `continuumJarvisBot` processes a Google Chat command, or `continuumJarvisWebApp` receives a JIRA webhook, that requires deferred processing.
   - From: `googlePubSub` or external webhook
   - To: `continuumJarvisBot` or `continuumJarvisWebApp`
   - Protocol: Google Pub/Sub / HTTPS webhook POST

2. **Enqueues RQ job**: The handler calls RQ's `enqueue()` with the job function reference and arguments.
   - From: `continuumJarvisBot` or `continuumJarvisWebApp`
   - To: `continuumJarvisRedis`
   - Protocol: Redis (RQ enqueue — RPUSH to the queue key)

3. **Dequeues and executes job**: `workerRqWorker` in `continuumJarvisWorker` picks up the job from the Redis queue.
   - From: `continuumJarvisRedis`
   - To: `continuumJarvisWorker` (`workerPluginJobs`)
   - Protocol: Redis (RQ dequeue — BLPOP)

4. **Executes job business logic**: `workerPluginJobs` performs the deferred work — may call JIRA, PagerDuty, Google Chat API, GitHub, or other integrations depending on job type.
   - From: `continuumJarvisWorker`
   - To: External APIs / `continuumJarvisPostgres` / `googleChatApi`
   - Protocol: HTTPS / REST; PostgreSQL

5. **Persists result**: Job writes outcome or state to `continuumJarvisPostgres`.
   - From: `continuumJarvisWorker`
   - To: `continuumJarvisPostgres`
   - Protocol: PostgreSQL

### Scheduled (Recurring) Job Execution

1. **RQ Scheduler fires**: `workerScheduler` monitors scheduled job entries in `continuumJarvisRedis` and enqueues jobs when their scheduled time is reached.
   - From: `continuumJarvisWorker` (`workerScheduler`)
   - To: `continuumJarvisRedis`
   - Protocol: Redis (RQ Scheduler — reads schedule entries, pushes to job queue)

2. **Dequeues and executes scheduled job**: `workerRqWorker` picks up the enqueued job and executes it — same as steps 3–5 above.
   - From: `continuumJarvisRedis`
   - To: `continuumJarvisWorker` (`workerPluginJobs`)
   - Protocol: Redis (RQ dequeue)

3. **Sends scheduled notification**: If the job is a recurring notification (e.g., daily on-call reminder, maintenance window alert), `workerPluginJobs` calls Google Chat API to post the notification.
   - From: `continuumJarvisWorker`
   - To: `googleChatApi`
   - Protocol: HTTPS / REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Job execution fails | RQ retries up to configured retry limit; then moves job to the RQ failed queue | Job is visible in `/django-rq/` failed queue; operator must investigate and retry |
| Redis unavailable | `continuumJarvisBot` and `continuumJarvisWebApp` cannot enqueue; workers cannot dequeue | All background processing halts; restores automatically when Redis recovers |
| Job function raises unhandled exception | RQ catches exception, stores traceback in failed job entry | Failed job persists in Redis failed queue; no automatic retry unless configured |
| Scheduled job takes longer than next interval | RQ does not prevent overlap; duplicate execution possible for recurring jobs | Operator should monitor job duration and adjust schedule intervals |

## Sequence Diagram

```
# Ad-hoc job path
continuumJarvisBot -> continuumJarvisRedis: enqueue(create_change_job, args)
continuumJarvisWorker -> continuumJarvisRedis: BLPOP (dequeue job)
continuumJarvisRedis --> continuumJarvisWorker: Job payload
continuumJarvisWorker -> jiraApi: Execute job (e.g., create ticket)
continuumJarvisWorker -> continuumJarvisPostgres: Persist result
continuumJarvisWorker -> googleChatApi: Send notification

# Scheduled job path
workerScheduler -> continuumJarvisRedis: Check schedule entries
continuumJarvisRedis --> workerScheduler: Jobs due for execution
workerScheduler -> continuumJarvisRedis: Enqueue due jobs
workerRqWorker -> continuumJarvisRedis: BLPOP (dequeue)
workerRqWorker -> workerPluginJobs: Execute scheduled job
workerPluginJobs -> googleChatApi: Post recurring notification
```

## Related

- Architecture dynamic view: `dynamic-backgroundJobScheduling` (not yet defined in DSL)
- Related flows: [Change Approval Workflow](change-approval-workflow.md), [Incident Response Orchestration](incident-response-orchestration.md), [On-Call Lookup and Notification](on-call-lookup-notification.md)
