---
service: "calcom"
title: "Background Reminder and Notification Dispatch"
generated: "2026-03-03"
type: flow
flow_name: "reminder-dispatch"
flow_type: asynchronous
trigger: "Scheduled time threshold before a booked meeting is reached; Worker polls the PostgreSQL job queue"
participants:
  - "continuumCalcomService"
  - "continuumCalcomWorkerService"
  - "calcomWorker_jobScheduler"
  - "calcomWorker_workflowExecutor"
  - "calcomWorker_reminderDispatcher"
  - "continuumCalcomPostgres"
  - "gmailSmtpService"
architecture_ref: "components-continuum-calcom-worker-service"
---

# Background Reminder and Notification Dispatch

## Summary

This flow describes how the Cal.com Worker Service processes asynchronous scheduling reminder and follow-up notification jobs. When a booking is created, the main Cal.com Service enqueues background jobs in the PostgreSQL database. The Worker Service's Job Scheduler continuously polls for pending jobs, dispatches them to the Workflow Executor, and the Reminder Dispatcher ultimately delivers reminder emails via Gmail SMTP to meeting participants before their scheduled meeting time.

## Trigger

- **Type**: schedule / event-driven
- **Source**: Jobs enqueued in `continuumCalcomPostgres` by `continuumCalcomService` at booking creation time; triggered when the scheduled job execution time is reached
- **Frequency**: Continuous background processing; reminder timing is determined by Cal.com workflow configuration (e.g., 24 hours before meeting, 1 hour before meeting)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cal.com Service | Creates asynchronous reminder jobs in the PostgreSQL job queue at booking time | `continuumCalcomService` |
| Cal.com Worker Service | Background runtime that hosts all three worker components | `continuumCalcomWorkerService` |
| Job Scheduler | Polls PostgreSQL for pending jobs; dequeues and dispatches them to the Workflow Executor | `calcomWorker_jobScheduler` |
| Workflow Executor | Executes multi-step reminder and follow-up workflows | `calcomWorker_workflowExecutor` |
| Reminder Dispatcher | Dispatches the actual reminder email notification | `calcomWorker_reminderDispatcher` |
| Cal.com PostgreSQL | Stores the job queue; persists workflow execution state | `continuumCalcomPostgres` |
| Gmail SMTP | Delivers reminder email to meeting participants | `gmailSmtpService` |

## Steps

1. **Enqueues reminder job**: When a booking is confirmed, the Cal.com Service writes a scheduled reminder job to the PostgreSQL-backed job queue, specifying the delivery time and recipient details.
   - From: `continuumCalcomService`
   - To: `continuumCalcomPostgres`
   - Protocol: PostgreSQL

2. **Polls for pending jobs**: The Job Scheduler continuously reads the PostgreSQL job queue for jobs whose scheduled execution time has arrived.
   - From: `calcomWorker_jobScheduler`
   - To: `continuumCalcomPostgres`
   - Protocol: PostgreSQL

3. **Dequeues and dispatches job**: The Job Scheduler dequeues a pending reminder job and dispatches it to the Workflow Executor for processing.
   - From: `calcomWorker_jobScheduler`
   - To: `calcomWorker_workflowExecutor`
   - Protocol: Internal

4. **Executes reminder workflow**: The Workflow Executor processes the multi-step reminder workflow (e.g., resolve recipient, compose message, determine delivery channel).
   - From: `calcomWorker_workflowExecutor`
   - To: `calcomWorker_reminderDispatcher`
   - Protocol: Internal

5. **Dispatches reminder notification**: The Reminder Dispatcher sends the reminder email to the meeting participant(s) via Gmail SMTP.
   - From: `calcomWorker_reminderDispatcher`
   - To: `gmailSmtpService`
   - Protocol: SMTP/TLS (smtp.gmail.com:465)

6. **Persists workflow completion state**: The Worker Service updates the job record in PostgreSQL to mark the workflow as completed.
   - From: `continuumCalcomWorkerService`
   - To: `continuumCalcomPostgres`
   - Protocol: PostgreSQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SMTP delivery failure | Error surfaces in Worker logs; reminder email not delivered | Meeting participant does not receive reminder; no automatic retry at Groupon layer |
| Worker pod crash during job processing | Kubernetes liveness probe restarts pod; pending jobs remain in PostgreSQL queue | Jobs re-processed on pod restart (potential duplicate delivery depending on Cal.com job idempotency) |
| Database connectivity loss | Worker cannot read job queue; all processing halts | Jobs accumulate in queue; processing resumes when database connectivity is restored |
| Job processing errors | Logged by worker; behavior depends on upstream Cal.com job handling | May result in undelivered reminders; check worker logs for error details |

## Sequence Diagram

```
continuumCalcomService -> continuumCalcomPostgres: Enqueue reminder job at booking creation time
calcomWorker_jobScheduler -> continuumCalcomPostgres: Poll for pending jobs (scheduled)
continuumCalcomPostgres --> calcomWorker_jobScheduler: Return pending job(s)
calcomWorker_jobScheduler -> calcomWorker_workflowExecutor: Dequeue and dispatch job
calcomWorker_workflowExecutor -> calcomWorker_reminderDispatcher: Execute reminder dispatch task
calcomWorker_reminderDispatcher -> gmailSmtpService: Send reminder email (SMTP/TLS)
gmailSmtpService --> calcomWorker_reminderDispatcher: Email delivered
calcomWorker_workflowExecutor -> continuumCalcomPostgres: Persist workflow completion state
```

## Related

- Architecture dynamic view: `components-continuum-calcom-worker-service`
- Related flows: [Booking Confirmation Flow](booking-confirmation.md)
