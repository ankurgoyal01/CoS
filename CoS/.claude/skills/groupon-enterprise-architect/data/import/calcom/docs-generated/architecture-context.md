---
service: "calcom"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumCalcomService"
    - "continuumCalcomWorkerService"
    - "continuumCalcomPostgres"
---

# Architecture Context

## System Context

Calcom sits within the `continuumSystem` (Continuum Platform) as Groupon's managed instance of the Cal.com open-source scheduling product. It serves end users (via browser) who book meetings at `https://meet.groupon.com` and administrators who configure scheduling settings. The service depends on a GDS-managed PostgreSQL database for persistent storage and uses Gmail SMTP for transactional email delivery. The primary web/API container offloads asynchronous background work (reminders, follow-ups) to a dedicated worker container connected via an internal job queue backed by the same PostgreSQL database.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Cal.com Service | `continuumCalcomService` | Application | Docker (calcom/cal.com), Kubernetes | v4.3.5 | Primary Cal.com web/API runtime for meeting scheduling and administration |
| Cal.com Worker Service | `continuumCalcomWorkerService` | Application / Worker | Docker (calcom/cal.com), Kubernetes | v4.3.5 | Background worker runtime that processes asynchronous scheduling workflows and email-related tasks |
| Cal.com PostgreSQL | `continuumCalcomPostgres` | Database | PostgreSQL | — | GDS-managed PostgreSQL databases for staging and production |

## Components by Container

### Cal.com Service (`continuumCalcomService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Booking UI (`calcom_bookingUi`) | Next.js frontend rendering scheduling pages and interactive booking workflows | TypeScript/Next.js |
| Scheduling API (`calcom_schedulingApi`) | Server-side API handling booking creation, availability queries, and calendar sync | TypeScript/Node.js |
| Auth and Session Manager (`calcom_authSessionManager`) | Manages authentication, session tokens, and access control | TypeScript/Node.js |
| Notification Orchestrator (`calcom_notificationOrchestrator`) | Orchestrates confirmation and reminder email and notification dispatch | TypeScript/Node.js |

### Cal.com Worker Service (`continuumCalcomWorkerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Job Scheduler (`calcomWorker_jobScheduler`) | Manages cron-based and event-driven job scheduling for background tasks | TypeScript/Node.js |
| Workflow Executor (`calcomWorker_workflowExecutor`) | Executes multi-step workflows for reminders and follow-ups | TypeScript/Node.js |
| Reminder Dispatcher (`calcomWorker_reminderDispatcher`) | Dispatches scheduled reminders and notification tasks | TypeScript/Node.js |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `calcom_bookingUi` | `calcom_schedulingApi` | Submits scheduling requests and availability selections | Internal |
| `calcom_schedulingApi` | `calcom_authSessionManager` | Validates session identity and access controls | Internal |
| `calcom_schedulingApi` | `calcom_notificationOrchestrator` | Triggers downstream confirmation and reminder workflows | Internal |
| `calcomWorker_jobScheduler` | `calcomWorker_workflowExecutor` | Dequeues and dispatches pending asynchronous jobs | Internal |
| `calcomWorker_workflowExecutor` | `calcomWorker_reminderDispatcher` | Executes reminder and notification delivery tasks | Internal |
| `continuumCalcomService` | `continuumCalcomWorkerService` | Creates asynchronous scheduling and reminder jobs | Internal job queue |
| `continuumCalcomService` | `continuumCalcomPostgres` | Reads and writes scheduling, account, and configuration data | PostgreSQL |
| `continuumCalcomWorkerService` | `continuumCalcomPostgres` | Reads pending jobs and persists workflow state | PostgreSQL |
| `continuumCalcomService` | `gmailSmtpService` | Sends scheduling confirmations and transactional emails | SMTP/TLS |
| `continuumCalcomWorkerService` | `gmailSmtpService` | Sends reminder and follow-up notification emails | SMTP/TLS |

## Architecture Diagram References

- Component (Cal.com Service): `components-continuum-calcom-service`
- Component (Cal.com Worker Service): `components-continuum-calcom-worker-service`
- Dynamic view (Booking Confirmation Flow): `dynamic-calcom-booking-confirmation`
