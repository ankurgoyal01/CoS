---
service: "garvis"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Garvis (Jarvis).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Change Approval Workflow](change-approval-workflow.md) | event-driven | Google Chat command or JIRA webhook | Engineer submits a change request via Google Chat; Jarvis creates a JIRA ticket, tracks approvals, and notifies relevant parties |
| [Incident Response Orchestration](incident-response-orchestration.md) | event-driven | Google Chat command | On-call engineer declares an incident; Jarvis creates a JIRA incident, pages PagerDuty, opens a Google Chat war room, and coordinates updates |
| [On-Call Lookup and Notification](on-call-lookup-notification.md) | synchronous | Google Chat command | User queries who is on-call for a service; Jarvis queries PagerDuty and returns the current on-call engineer with contact details |
| [Background Job Scheduling](background-job-scheduling.md) | scheduled / asynchronous | RQ Scheduler timer or explicit enqueue | Recurring and deferred tasks (notifications, status checks, report generation) are enqueued to Redis and executed by RQ workers |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The [Change Approval Workflow](change-approval-workflow.md) spans `continuumJarvisBot`, `continuumJarvisWorker`, `continuumJarvisPostgres`, `jiraApi`, and `googleChatApi`.
- The [Incident Response Orchestration](incident-response-orchestration.md) spans `continuumJarvisBot`, `continuumJarvisWorker`, `jiraApi`, `googleChatApi`, and PagerDuty.
- Dynamic views for these flows are not yet defined in the Structurizr DSL (`views/dynamics.dsl` is currently empty).
