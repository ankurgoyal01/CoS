---
service: "ARQWeb"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for ARQWeb.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Access Request Submission](access-request-submission.md) | synchronous | User submits an access request via the web UI or API | Employee submits a new access request; ARQWeb validates, persists, and enqueues approval and Jira ticket creation jobs |
| [Access Request Approval](access-request-approval.md) | synchronous | Approver reviews and acts on a pending request | Manager or admin approves or rejects a request; ARQWeb records the decision, updates Jira, and enqueues provisioning jobs |
| [Access Provisioning (Worker)](access-provisioning-worker.md) | asynchronous | Approved request job dequeued by ARQ Worker | ARQ Worker executes Active Directory, GitHub Enterprise, and Cyclops changes to provision the approved access |
| [Scheduled User and Service Sync](scheduled-user-service-sync.md) | scheduled | ARQ Worker cron schedule (periodic) | ARQ Worker synchronizes employee and manager data from Workday and service chain data from Service Portal into the ARQ database |
| [Employee Onboarding](employee-onboarding.md) | synchronous | New employee onboarding workflow trigger | Automated onboarding batch submits standard access requests for a new employee; worker provisions default access across AD and GitHub |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |
| Synchronous + async handoff | 1 |

## Cross-Service Flows

- The access provisioning flow spans `continuumArqWebApp`, `continuumArqWorker`, `continuumArqPostgres`, `activeDirectory`, `githubEnterprise`, and `cyclops`.
- The Jira ticket lifecycle spans `continuumArqWebApp`, `continuumArqWorker`, and `continuumJiraService`.
- Workday and Service Portal sync flows are internal to `continuumArqWorker` with no inbound dependencies from other Continuum services.
